import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/plant.dart';

class PlantReferenceImageService {
  PlantReferenceImageService._();

  static final http.Client _client = http.Client();
  static final Map<String, Future<List<String>>> _cache =
      <String, Future<List<String>>>{};

  static Future<List<String>> fetchImagesForPlant(Plant plant) {
    final key = [
      plant.scientificName.trim().toLowerCase(),
      plant.englishName.trim().toLowerCase(),
      plant.commonName.trim().toLowerCase(),
    ].join('|');

    return _cache.putIfAbsent(key, () => _loadImages(plant));
  }

  static Future<List<String>> _loadImages(Plant plant) async {
    final result = <String>[];
    final seen = <String>{};

    void addAll(Iterable<String> urls) {
      for (final url in urls) {
        final trimmed = url.trim();
        if (trimmed.isEmpty || !seen.add(trimmed)) {
          continue;
        }
        result.add(trimmed);
        if (result.length >= 4) {
          break;
        }
      }
    }

    final queries = <String>[
      plant.scientificName,
      plant.englishName,
      plant.commonName,
      ...plant.aliases.take(2),
    ]
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    for (final query in queries) {
      addAll(await _searchCommonsImageUrls(query));
      if (result.length >= 4) {
        break;
      }
    }

    addAll(_curatedGalleryForScientificName(plant.scientificName));
    return result.take(4).toList(growable: false);
  }

  static Future<List<String>> _searchCommonsImageUrls(String query) async {
    try {
      final uri = Uri.https(
        'commons.wikimedia.org',
        '/w/api.php',
        <String, String>{
          'action': 'query',
          'format': 'json',
          'generator': 'search',
          'gsrsearch': 'intitle:$query',
          'gsrnamespace': '6',
          'gsrlimit': '8',
          'prop': 'imageinfo',
          'iiprop': 'url',
          'iiurlwidth': '1200',
          'origin': '*',
        },
      );

      final response = await _client.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const <String>[];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const <String>[];
      }

      final queryNode = decoded['query'];
      if (queryNode is! Map<String, dynamic>) {
        return const <String>[];
      }

      final pages = queryNode['pages'];
      if (pages is! Map) {
        return const <String>[];
      }

      final urls = <String>[];
      for (final page in pages.values) {
        if (page is! Map) {
          continue;
        }
        final imageInfo = page['imageinfo'];
        if (imageInfo is! List || imageInfo.isEmpty) {
          continue;
        }
        final first = imageInfo.first;
        if (first is! Map) {
          continue;
        }
        final thumbUrl = first['thumburl']?.toString() ?? '';
        final directUrl = first['url']?.toString() ?? '';
        final candidate = thumbUrl.isNotEmpty ? thumbUrl : directUrl;
        if (_isSupportedImage(candidate)) {
          urls.add(candidate);
        }
      }

      return urls;
    } catch (_) {
      return const <String>[];
    }
  }

  static bool _isSupportedImage(String url) {
    final normalized = url.toLowerCase();
    return normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.png') ||
        normalized.endsWith('.webp');
  }
}

List<String> _curatedGalleryForScientificName(String scientificName) {
  final key = scientificName.trim().toLowerCase();
  final fileNames = _galleryFileNames[key] ?? const <String>[];
  return fileNames.map(_commonsFileUrl).toList(growable: false);
}

String _commonsFileUrl(String fileName) {
  return Uri.https(
    'commons.wikimedia.org',
    '/wiki/Special:FilePath/$fileName',
  ).toString();
}

const Map<String, List<String>> _galleryFileNames = <String, List<String>>{
  'epipremnum aureum': <String>[
    'Epipremnum aureum.jpg',
    'Epipremnum aureum3.jpg',
    'Epipremnum aureum (Golden Pothos).jpg',
    'Epipremnum aureum (Golden pothos).jpg',
  ],
  'monstera deliciosa': <String>[
    'Indoor Monstera deliciosa.jpg',
    'Monstera deliciosa.JPG',
    'Monstera deliciosa 002.jpg',
    'Monstera deliciosa (23516285899).jpg',
  ],
  'dracaena trifasciata': <String>[
    'Dracaena trifasciata 12694999.jpg',
    'Dracaena trifasciata 148931365.jpg',
    'Dracaena trifasciata 21744978.jpg',
    'Dracaena trifasciata 127376038.jpg',
  ],
  'ficus lyrata': <String>[
    'Ficus lyrata DSCN4457.jpg',
    'Ficus lyrata.jpg',
    'Ficus lyrata 14zz.jpg',
    'Ficus lyrata2.jpg',
  ],
  'spathiphyllum wallisii': <String>[
    'Spathiphyllum wallisii - MHNT.jpg',
    'SpathiphyllumWallisii.jpg',
    'Spathiphyllum wallisii.JPG',
    'Spathiphyllum wallisii(1).jpg',
  ],
  'zamioculcas zamiifolia': <String>[
    'Zamioculcas zamiifolia.jpg',
    'Zamioculcas zamiifolia.png',
    'Zamioculcas zamiifolia 8zz.jpg',
    'Zamioculcas zamiifolia 6zz.jpg',
  ],
};
