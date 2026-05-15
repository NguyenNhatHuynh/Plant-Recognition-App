import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../models/recognition_result.dart';

class RecognitionService {
  final String apiKey;
  final http.Client _client;

  RecognitionService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<RecognitionResult> recognizePlant(XFile imageFile) async {
    if (apiKey.trim().isEmpty) {
      throw StateError(
        'Gemini API key is missing. Pass --dart-define=GEMINI_API_KEY=... when running the app.',
      );
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );
    final bytes = await imageFile.readAsBytes();
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt},
            {
              'inline_data': {
                'mime_type': _mimeTypeFor(imageFile.path),
                'data': base64Encode(bytes),
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'max_output_tokens': 1200,
        'response_mime_type': 'application/json',
      },
    });

    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body));
    }

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
    final rawText = _extractText(responseJson);
    if (rawText == null || rawText.trim().isEmpty) {
      throw Exception('Gemini returned an empty result.');
    }

    final normalized = _stripCodeFences(rawText.trim());
    final parsed = jsonDecode(normalized) as Map<String, dynamic>;
    return RecognitionResult.fromGeminiJson(
      parsed,
      imagePath: imageFile.path,
    );
  }

  String get _prompt {
    return '''
Bạn là chuyên gia nhận diện thực vật.
Phân tích ảnh cây và trả về CHỈ JSON hợp lệ theo đúng cấu trúc sau:
{
  "primary": {
    "common_name": "Tên phổ thông bằng tiếng Việt",
    "scientific_name": "Tên khoa học",
    "family": "Họ thực vật",
    "description": "Mô tả sinh học ngắn gọn, chính xác",
    "habitat": "Môi trường sống điển hình",
    "uses": ["Ứng dụng 1", "Ứng dụng 2"],
    "confidence": 0.0
  },
  "alternatives": [
    {
      "common_name": "Tên phổ thông",
      "scientific_name": "Tên khoa học",
      "family": "Họ thực vật",
      "description": "Mô tả ngắn",
      "habitat": "Môi trường sống",
      "uses": ["Ứng dụng"],
      "confidence": 0.0
    }
  ],
  "analysis_note": "Nhận xét ngắn về mức độ chắc chắn hoặc dấu hiệu nhận diện"
}

Quy tắc:
- Trả về tiếng Việt cho common_name, description, habitat, uses, analysis_note.
- scientific_name phải là tên Latin chuẩn nếu biết.
- confidence nằm trong khoảng 0.0 đến 1.0.
- Nếu không chắc chắn, vẫn chọn loài gần nhất và giảm confidence.
- Không được trả markdown, không được thêm văn bản ngoài JSON.
''';
  }

  String _mimeTypeFor(String filePath) {
    switch (p.extension(filePath).toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
      case '.heif':
        return 'image/heic';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
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
}
