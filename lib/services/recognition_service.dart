import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../models/recognition_result.dart';

class RecognitionException implements Exception {
  final String message;

  const RecognitionException(this.message);

  @override
  String toString() => message;
}

class RecognitionService {
  static const int _maxOutputTokens = 5000;

  final String apiKey;
  final String remoteBaseUrl;
  final http.Client _client;

  RecognitionService({
    required this.apiKey,
    this.remoteBaseUrl = '',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<RecognitionResult> recognizePlant(XFile imageFile) async {
    if (remoteBaseUrl.isNotEmpty) {
      return _withRetry(() => _recognizeViaBackend(imageFile));
    }

    return _withRetry(() => _recognizeDirectly(imageFile));
  }

  Future<RecognitionResult> _withRetry(
    Future<RecognitionResult> Function() action,
  ) async {
    const retryDelays = <Duration>[
      Duration(seconds: 1),
      Duration(seconds: 2),
    ];

    for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
      try {
        return await action();
      } on RecognitionException catch (error) {
        final shouldRetry =
            attempt < retryDelays.length && _isRetriableError(error.message);
        if (!shouldRetry) {
          rethrow;
        }
        await Future<void>.delayed(retryDelays[attempt]);
      } on SocketException {
        if (attempt >= retryDelays.length) {
          throw const RecognitionException(
            'Khong the ket noi toi dich vu nhan dien. Vui long kiem tra mang va thu lai.',
          );
        }
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }

    throw const RecognitionException(
      'Khong the nhan dien anh vao luc nay. Vui long thu lai sau.',
    );
  }

  Future<RecognitionResult> _recognizeDirectly(XFile imageFile) async {
    if (apiKey.trim().isEmpty) {
      throw const RecognitionException(
        'Thieu GEMINI_API_KEY. Hay kiem tra file .env hoac cau hinh moi truong cua ban.',
      );
    }

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/gemini-2.5-flash:generateContent',
      {'key': apiKey},
    );
    final bytes = await imageFile.readAsBytes();
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': _mimeTypeFor(imageFile.path),
                'data': base64Encode(bytes),
              },
            },
            {'text': _prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'max_output_tokens': _maxOutputTokens,
        'response_mime_type': 'application/json',
      },
    });

    final response = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw const RecognitionException(
            'Yeu cau nhan dien bi qua thoi gian. Vui long kiem tra mang va thu lai.',
          ),
        );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logDebug(
        'Gemini direct request failed.',
        payload: response.body,
      );
      throw RecognitionException(
        _mapApiErrorMessage(
          _extractErrorMessage(response.body),
          statusCode: response.statusCode,
        ),
      );
    }

    final responseJson = _decodeRootResponse(
      response.body,
      context: 'Gemini direct response',
    );
    _ensureResponseCompleted(
      responseJson,
      context: 'Gemini direct response',
    );

    final rawText = _extractText(responseJson);
    if (rawText == null || rawText.trim().isEmpty) {
      _logDebug(
        'Gemini direct response did not contain text parts.',
        payload: response.body,
      );
      throw const RecognitionException(
        'Dich vu nhan dien khong tra ve ket qua hop le. Vui long thu lai.',
      );
    }

    final normalized = _stripCodeFences(rawText.trim());
    final parsed = _decodeJsonObjectWithContext(
      normalized,
      context: 'Gemini direct response',
    );

    try {
      return RecognitionResult.fromGeminiJson(
        parsed,
        imagePath: imageFile.path,
      );
    } on FormatException catch (error, stackTrace) {
      _logDebug(
        'Gemini recognition payload schema mismatch: ${error.message}',
        payload: normalized,
        stackTrace: stackTrace,
      );
      throw const RecognitionException(
        'Du lieu tra ve tu dich vu nhan dien khong dung cau truc mong doi. Vui long thu lai.',
      );
    }
  }

  Future<RecognitionResult> _recognizeViaBackend(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final uri = Uri.parse(
      '${remoteBaseUrl.replaceAll(RegExp(r'/$'), '')}/recognize',
    );
    final response = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'mime_type': _mimeTypeFor(imageFile.path),
            'image_base64': base64Encode(bytes),
          }),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw const RecognitionException(
            'May chu nhan dien phan hoi qua cham. Vui long thu lai sau it phut.',
          ),
        );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logDebug(
        'Recognition backend request failed.',
        payload: response.body,
      );
      throw RecognitionException(
        _mapApiErrorMessage(
          _extractErrorMessage(response.body),
          statusCode: response.statusCode,
        ),
      );
    }

    final responseJson = _decodeRootResponse(
      response.body,
      context: 'Recognition backend response',
    );
    final payload = responseJson['result'];
    final recognizedJson = payload is Map<String, dynamic>
        ? payload
        : payload is Map
            ? Map<String, dynamic>.from(payload)
            : responseJson;

    try {
      return RecognitionResult.fromGeminiJson(
        recognizedJson,
        imagePath: imageFile.path,
      );
    } on FormatException catch (error, stackTrace) {
      _logDebug(
        'Recognition backend payload schema mismatch: ${error.message}',
        payload: jsonEncode(recognizedJson),
        stackTrace: stackTrace,
      );
      throw const RecognitionException(
        'May chu nhan dien tra ve du lieu khong dung cau truc mong doi.',
      );
    }
  }

  String get _prompt {
    return '''
Ban la chuyen gia nhan dien thuc vat.
Phan tich anh cay va tra ve CHI JSON hop le theo dung cau truc sau:
{
  "primary": {
    "common_name": "Ten pho thong bang tieng Viet",
    "aliases": ["Ten goi khac 1", "Ten goi khac 2"],
    "english_name": "Ten pho bien bang tieng Anh",
    "scientific_name": "Ten khoa hoc",
    "family": "Ho thuc vat",
    "description": "Mo ta ngan gon, de hieu, tap trung vao dac diem nhan dien cua cay",
    "habitat": "Moi truong song dien hinh",
    "light_requirement": "Yeu cau anh sang",
    "watering_needs": "Nhu cau tuoi nuoc",
    "care_level": "De, Trung binh hoac Kho",
    "suitable_temperature": "Khoang nhiet do thich hop",
    "soil_type": "Loai dat phu hop",
    "fertilizing_tips": "Meo bon phan ngan gon",
    "toxicity_warning": "Canh bao doc tinh voi tre em va thu cung",
    "uses": ["Ung dung 1", "Ung dung 2"],
    "maximum_size": "Kich thuoc toi da khi truong thanh",
    "feng_shui_meaning": "Y nghia phong thuy neu co",
    "origin": "Nguon goc xuat xu",
    "common_issues": "Dau hieu benh hoac van de thuong gap",
    "confidence": 0.0
  },
  "alternatives": [
    {
      "common_name": "Ten pho thong",
      "aliases": ["Ten goi khac"],
      "english_name": "Ten tieng Anh",
      "scientific_name": "Ten khoa hoc",
      "family": "Ho thuc vat",
      "description": "Mo ta ngan",
      "habitat": "Moi truong song",
      "light_requirement": "Yeu cau anh sang",
      "watering_needs": "Nhu cau tuoi nuoc",
      "care_level": "Do kho cham soc",
      "suitable_temperature": "Khoang nhiet do",
      "soil_type": "Loai dat",
      "fertilizing_tips": "Meo bon phan",
      "toxicity_warning": "Canh bao doc tinh",
      "uses": ["Ung dung"],
      "maximum_size": "Kich thuoc toi da",
      "feng_shui_meaning": "Y nghia phong thuy",
      "origin": "Nguon goc",
      "common_issues": "Van de thuong gap",
      "confidence": 0.0
    }
  ],
  "analysis_note": "Nhan xet ngan ve muc do chac chan hoac dau hieu nhan dien"
}

Quy tac:
- Tra ve tieng Viet cho common_name, aliases, description, habitat, light_requirement, watering_needs, care_level, suitable_temperature, soil_type, fertilizing_tips, toxicity_warning, uses, maximum_size, feng_shui_meaning, origin, common_issues, analysis_note.
- english_name la ten pho bien quoc te neu biet, khong thi de chuoi rong.
- scientific_name phai la ten Latin chuan neu biet.
- aliases la cac ten goi dia phuong, ten goi cu, hoac ten thuong mai pho bien; neu khong co thi tra ve [].
- care_level chi nhan mot trong ba gia tri: "De", "Trung binh", "Kho" neu co du lieu.
- confidence nam trong khoang 0.0 den 1.0.
- Neu khong chac chan, van chon loai gan nhat va giam confidence.
- Neu khong nhan ra ro, van tra dung JSON va de confidence thap.
- Khong duoc tra markdown, khong duoc them van ban ngoai JSON.
''';
  }

  String _mimeTypeFor(String filePath) {
    switch (p.extension(filePath).toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.heif':
        return 'image/heif';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Map<String, dynamic> _decodeRootResponse(
    String responseBody, {
    required String context,
  }) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      _logDebug(
        '$context is not a JSON object.',
        payload: responseBody,
      );
      throw const RecognitionException(
        'Dich vu nhan dien tra ve du lieu khong hop le.',
      );
    } on FormatException catch (error, stackTrace) {
      _logDebug(
        '$context root JSON parse failed: ${error.message}',
        payload: responseBody,
        stackTrace: stackTrace,
      );
      throw const RecognitionException(
        'Dich vu nhan dien tra ve du lieu khong doc duoc. Vui long thu lai.',
      );
    }
  }

  void _ensureResponseCompleted(
    Map<String, dynamic> responseJson, {
    required String context,
  }) {
    final candidates = responseJson['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return;
    }

    final first = candidates.first;
    if (first is! Map<String, dynamic>) {
      return;
    }

    final finishReason = first['finishReason']?.toString();
    if (finishReason == null || finishReason == 'STOP') {
      return;
    }

    _logDebug(
      '$context finished with non-STOP reason: $finishReason',
      payload: jsonEncode(first),
    );

    if (finishReason == 'MAX_TOKENS') {
      throw const RecognitionException(
        'Ket qua nhan dien bi cat do gioi han do dai phan hoi. Vui long thu lai voi anh ro hon hoac thu lai sau.',
      );
    }

    if (finishReason == 'SAFETY') {
      throw const RecognitionException(
        'Dich vu nhan dien da tu choi phan hoi cho anh nay. Vui long thu voi anh khac.',
      );
    }

    throw RecognitionException(
      'Dich vu nhan dien dung som ($finishReason). Vui long thu lai.',
    );
  }

  String? _extractText(Map<String, dynamic> responseJson) {
    final candidates = responseJson['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      if (first is Map<String, dynamic>) {
        final content = first['content'];
        if (content is Map<String, dynamic>) {
          final parts = content['parts'];
          if (parts is List) {
            final buffer = StringBuffer();
            for (final part in parts) {
              if (part is Map<String, dynamic>) {
                final text = part['text'];
                if (text != null) {
                  buffer.write(text.toString());
                }
              }
            }
            final text = buffer.toString();
            if (text.isNotEmpty) {
              return text;
            }
          }
        }
      }
    }

    final text = responseJson['text'];
    if (text is String && text.isNotEmpty) {
      return text;
    }
    return null;
  }

  Map<String, dynamic> _decodeJsonObjectWithContext(
    String input, {
    required String context,
  }) {
    try {
      final decoded = jsonDecode(input);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      _logDebug(
        '$context is not a JSON object.',
        payload: input,
      );
      throw const RecognitionException(
        'Du lieu tra ve tu dich vu nhan dien khong dung dinh dang mong doi.',
      );
    } on FormatException catch (error, stackTrace) {
      _logDebug(
        '$context JSON parse failed: ${error.message}',
        payload: input,
        stackTrace: stackTrace,
      );
      throw const RecognitionException(
        'Dich vu nhan dien tra ve du lieu chua hoan chinh. Vui long thu lai voi anh ro hon hoac thu lai sau.',
      );
    }
  }

  String _stripCodeFences(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('```')) {
      final lines = trimmed.split('\n');
      if (lines.length >= 3) {
        return lines.sublist(1, lines.length - 1).join('\n').trim();
      }
    }
    return trimmed;
  }

  String _extractErrorMessage(String body) {
    try {
      final jsonBody = jsonDecode(body);
      if (jsonBody is Map<String, dynamic>) {
        final error = jsonBody['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message != null) {
            return message.toString();
          }
        }
      }
    } catch (_) {
      return body;
    }
    return body;
  }

  bool _isRetriableError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('high demand') ||
        normalized.contains('currently experiencing high demand') ||
        normalized.contains('temporarily unavailable') ||
        normalized.contains('resource exhausted') ||
        normalized.contains('quota') ||
        normalized.contains('503') ||
        normalized.contains('429');
  }

  String _mapApiErrorMessage(
    String message, {
    int? statusCode,
  }) {
    final normalized = message.toLowerCase();

    if (statusCode == 429 ||
        normalized.contains('high demand') ||
        normalized.contains('currently experiencing high demand') ||
        normalized.contains('resource exhausted')) {
      return 'He thong nhan dien dang qua tai. Ung dung da thu lai tu dong nhung chua thanh cong, vui long thu lai sau it phut.';
    }

    if (statusCode == 503 || normalized.contains('temporarily unavailable')) {
      return 'Dich vu nhan dien dang tam thoi khong kha dung. Vui long thu lai sau.';
    }

    if (normalized.contains('api key')) {
      return 'Cau hinh Gemini API key chua dung. Hay kiem tra lai file .env.';
    }

    return message;
  }

  void _logDebug(
    String message, {
    String? payload,
    StackTrace? stackTrace,
  }) {
    developer.log(
      payload == null ? message : '$message\n$payload',
      name: 'RecognitionService',
      stackTrace: stackTrace,
    );
  }
}
