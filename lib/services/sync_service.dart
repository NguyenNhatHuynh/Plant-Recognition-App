import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'database_service.dart';

class SyncService {
  static const String _remotePlantsTable = 'user_plants';
  static const String _remoteRecognitionTable = 'user_recognition_records';

  final AuthService _authService;
  final DatabaseService _databaseService;

  bool _isSyncing = false;
  bool _shouldRunAgain = false;

  SyncService({
    required AuthService authService,
    required DatabaseService databaseService,
  }) : _authService = authService,
       _databaseService = databaseService;

  Future<bool> syncInBackground() async {
    if (_isSyncing) {
      _shouldRunAgain = true;
      return false;
    }

    final client = _authService.client;
    final user = _authService.currentUser;
    if (client == null || user == null) {
      return false;
    }

    _isSyncing = true;
    var hasLocalChanges = false;

    try {
      do {
        _shouldRunAgain = false;
        hasLocalChanges =
            await _syncOnce(client: client, userId: user.id) || hasLocalChanges;
      } while (_shouldRunAgain);
    } finally {
      _isSyncing = false;
    }

    return hasLocalChanges;
  }

  Future<bool> _syncOnce({
    required SupabaseClient client,
    required String userId,
  }) async {
    try {
      await _pushPendingPlants(client: client, userId: userId);
      await _pushPendingRecognitionRecords(client: client, userId: userId);
      final pulledPlants = await _pullPlants(client: client, userId: userId);
      final pulledRecords = await _pullRecognitionRecords(
        client: client,
        userId: userId,
      );
      return pulledPlants || pulledRecords;
    } on PostgrestException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pushPendingPlants({
    required SupabaseClient client,
    required String userId,
  }) async {
    final plants = await _databaseService.getPlantsPendingSync();

    for (final plant in plants) {
      final localId = (plant['id'] as num?)?.toInt();
      if (localId == null) {
        continue;
      }

      try {
        final payload = <String, Object?>{
          'user_id': userId,
          'common_name': plant['common_name'] as String? ?? '',
          'aliases_json': plant['aliases_json'] as String? ?? '[]',
          'english_name': plant['english_name'] as String? ?? '',
          'scientific_name': plant['scientific_name'] as String? ?? '',
          'family': plant['family'] as String? ?? '',
          'description': plant['description'] as String? ?? '',
          'habitat': plant['habitat'] as String? ?? '',
          'light_requirement': plant['light_requirement'] as String? ?? '',
          'watering_needs': plant['watering_needs'] as String? ?? '',
          'care_level': plant['care_level'] as String? ?? '',
          'suitable_temperature':
              plant['suitable_temperature'] as String? ?? '',
          'soil_type': plant['soil_type'] as String? ?? '',
          'fertilizing_tips': plant['fertilizing_tips'] as String? ?? '',
          'toxicity_warning': plant['toxicity_warning'] as String? ?? '',
          'uses_json': plant['uses_json'] as String? ?? '[]',
          'maximum_size': plant['maximum_size'] as String? ?? '',
          'feng_shui_meaning': plant['feng_shui_meaning'] as String? ?? '',
          'origin': plant['origin'] as String? ?? '',
          'common_issues': plant['common_issues'] as String? ?? '',
          'image_path': _serializeImagePathForCloud(
            plant['image_path'] as String? ?? '',
          ),
          'is_favorite': (plant['is_favorite'] as num? ?? 0) != 0,
          'is_offline_available':
              (plant['is_offline_available'] as num? ?? 0) != 0,
          'updated_at':
              plant['updated_at'] as String? ??
              DateTime.now().toUtc().toIso8601String(),
        };

        final response = await client
            .from(_remotePlantsTable)
            .upsert(payload, onConflict: 'user_id,scientific_name')
            .select('id')
            .single();

        await _databaseService.markPlantSynced(
          localId,
          remoteId: response['id']?.toString() ?? '',
          userId: userId,
          syncedAt: DateTime.now().toUtc().toIso8601String(),
        );
      } catch (_) {
        await _databaseService.markPlantSyncFailed(localId);
      }
    }
  }

  Future<void> _pushPendingRecognitionRecords({
    required SupabaseClient client,
    required String userId,
  }) async {
    final records = await _databaseService.getRecognitionRecordsPendingSync();

    for (final record in records) {
      final localId = (record['id'] as num?)?.toInt();
      if (localId == null) {
        continue;
      }

      try {
        final payload = <String, Object?>{
          'user_id': userId,
          'plant_remote_id': record['plant_remote_id'] as String? ?? '',
          'plant_scientific_name':
              record['plant_scientific_name'] as String? ?? '',
          'image_path': _serializeImagePathForCloud(
            record['image_path'] as String? ?? '',
          ),
          'confidence': (record['confidence'] as num?)?.toDouble() ?? 0.0,
          'captured_at': record['captured_at'] as String? ?? '',
          'raw_json': record['raw_json'] as String? ?? '{}',
          'client_record_key': record['client_record_key'] as String? ?? '',
          'updated_at':
              record['updated_at'] as String? ??
              DateTime.now().toUtc().toIso8601String(),
        };

        final response = await client
            .from(_remoteRecognitionTable)
            .upsert(payload, onConflict: 'user_id,client_record_key')
            .select('id')
            .single();

        await _databaseService.markRecognitionRecordSynced(
          localId,
          remoteId: response['id']?.toString() ?? '',
          userId: userId,
          syncedAt: DateTime.now().toUtc().toIso8601String(),
        );
      } catch (_) {
        await _databaseService.markRecognitionRecordSyncFailed(localId);
      }
    }
  }

  Future<bool> _pullPlants({
    required SupabaseClient client,
    required String userId,
  }) async {
    final remotePlants = await client
        .from(_remotePlantsTable)
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: true);

    var changed = false;
    for (final item in remotePlants) {
      changed =
          await _databaseService.upsertPlantFromRemote(item, userId: userId) ||
          changed;
    }
    return changed;
  }

  Future<bool> _pullRecognitionRecords({
    required SupabaseClient client,
    required String userId,
  }) async {
    final remoteRecords = await client
        .from(_remoteRecognitionTable)
        .select()
        .eq('user_id', userId)
        .order('captured_at', ascending: true);

    var changed = false;
    for (final item in remoteRecords) {
      changed =
          await _databaseService.upsertRecognitionRecordFromRemote(
            item,
            userId: userId,
          ) ||
          changed;
    }
    return changed;
  }

  String _serializeImagePathForCloud(String imagePath) {
    final trimmed = imagePath.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return '';
  }
}
