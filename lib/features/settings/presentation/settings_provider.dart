import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_models.dart';

/// In-memory settings (persisted later via SharedPreferences if available).
class SettingsNotifier extends StateNotifier<AppSettingsState> {
  SettingsNotifier() : super(const AppSettingsState());

  void setConfirmBulkSend(bool v) =>
      state = state.copyWith(confirmBulkSend: v);

  void setConfirmDelete(bool v) => state = state.copyWith(confirmDelete: v);

  void setCompactLists(bool v) => state = state.copyWith(compactLists: v);

  void setDefaultHome(String v) => state = state.copyWith(defaultHome: v);

  void setShowModuleHints(bool v) =>
      state = state.copyWith(showModuleHints: v);

  void reset() => state = const AppSettingsState();
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettingsState>((ref) {
  return SettingsNotifier();
});
