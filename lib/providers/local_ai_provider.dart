import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/local_ai_service.dart';

const _enabledKey = 'local_ai_enabled';

/// Service IA locale, exposé en provider par cohérence avec `aiServiceProvider`
/// (meal_provider.dart).
final localAiServiceProvider = Provider<LocalAiService>((ref) => LocalAiService());

/// État de la fonctionnalité IA locale : `enabled` est le seul champ
/// persisté (préférence utilisateur) ; `isDownloaded` reflète toujours l'état
/// réel du disque via [LocalAiService.isModelReady] plutôt que d'être stocké
/// en double, pour éviter un indicateur périmé après un vidage de stockage.
class LocalAiSettings {
  final bool enabled;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;

  const LocalAiSettings({
    required this.enabled,
    required this.isDownloaded,
    this.isDownloading = false,
    this.downloadProgress = 0,
  });

  LocalAiSettings copyWith({
    bool? enabled,
    bool? isDownloaded,
    bool? isDownloading,
    double? downloadProgress,
  }) {
    return LocalAiSettings(
      enabled: enabled ?? this.enabled,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  /// Vrai si l'IA locale peut effectivement être utilisée pour une requête
  /// (activée par l'utilisateur ET modèle présent sur l'appareil).
  bool get isReadyToUse => enabled && isDownloaded;
}

/// Réglages de l'IA locale (scan + chat via Gemma3n), persistés localement.
/// Suit le même pattern que `notificationSettingsProvider`.
final localAiSettingsProvider =
    AsyncNotifierProvider<LocalAiSettingsNotifier, LocalAiSettings>(
  LocalAiSettingsNotifier.new,
);

class LocalAiSettingsNotifier extends AsyncNotifier<LocalAiSettings> {
  @override
  Future<LocalAiSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final service = ref.read(localAiServiceProvider);
    return LocalAiSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      isDownloaded: await service.isModelReady(),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.value;
    if (current == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    state = AsyncData(current.copyWith(enabled: enabled));
  }

  Future<void> startDownload() async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(isDownloading: true, downloadProgress: 0));
    try {
      final service = ref.read(localAiServiceProvider);
      await service.downloadModel(
        onProgress: (progress) {
          final latest = state.value;
          if (latest == null) return;
          state = AsyncData(latest.copyWith(downloadProgress: progress));
        },
      );
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(isDownloading: false, isDownloaded: true, downloadProgress: 1));
    } catch (e) {
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(isDownloading: false));
      rethrow;
    }
  }

  Future<void> deleteModel() async {
    final current = state.value;
    if (current == null) return;

    final service = ref.read(localAiServiceProvider);
    await service.deleteModel();
    state = AsyncData(current.copyWith(isDownloaded: false, downloadProgress: 0));
  }
}
