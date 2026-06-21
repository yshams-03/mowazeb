import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_preferences_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';

final settingsActionsProvider = Provider<SettingsActions>((ref) {
  return SettingsActions(ref);
});

class SettingsActions {
  SettingsActions(this._ref);

  final Ref _ref;

  Future<void> updateCalculationMethod(String method) async {
    await _updateSettings({'calculationMethod': method});
  }

  Future<void> updateMadhab(String madhab) async {
    await _updateSettings({'madhab': madhab});
  }

  Future<void> updateHomeAddress(String address) async {
    await _updateSettings({'homeAddress': address.trim()});
  }

  Future<void> updateNotificationPrayers(List<String> prayers) async {
    await _updateSettings({'notificationPrayers': prayers});
  }

  Future<void> signOut() async {
    await _ref.read(authControllerProvider.notifier).signOut();
  }

  Future<void> deleteAccount() async {
    final auth = _ref.read(firebaseAuthProvider);
    final firestore = _ref.read(firestoreProvider);
    final user = auth.currentUser;
    if (user == null) return;

    await firestore.doc(FirestorePaths.userDoc(user.uid)).delete();
    await user.delete();
  }

  Future<void> _updateSettings(Map<String, dynamic> data) async {
    final uid = _ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;
    await _ref.read(firestoreProvider).doc(FirestorePaths.userSettings(uid)).set(
          data,
          SetOptions(merge: true),
        );
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _homeController = TextEditingController();
  bool _homeDirty = false;

  @override
  void dispose() {
    _homeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(userSettingsProvider).valueOrNull;
    final prefs = ref.watch(appPreferencesProvider);
    final actions = ref.watch(settingsActionsProvider);

    if (settings?.homeAddress != null && !_homeDirty) {
      _homeController.text = settings!.homeAddress!;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: l10n.prayerCalculation),
          _DropdownTile<String>(
            label: l10n.calculationMethod,
            value: CalculationMethods.parse(settings?.calculationMethod),
            items: CalculationMethods.all,
            onChanged: actions.updateCalculationMethod,
          ),
          _DropdownTile<String>(
            label: l10n.madhabAsr,
            value: settings?.madhab ?? MadhabOptions.standard,
            items: MadhabOptions.all,
            onChanged: actions.updateMadhab,
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: l10n.language),
          _DropdownTile<String>(
            label: l10n.language,
            value: prefs.localeCode,
            items: const ['en', 'ar'],
            itemLabel: (code) =>
                code == 'ar' ? l10n.languageArabic : l10n.languageEnglish,
            onChanged: (code) =>
                ref.read(appPreferencesProvider.notifier).setLocale(code),
          ),
          SwitchListTile(
            title: Text(l10n.arabicNumerals),
            subtitle: Text(l10n.arabicNumeralsSubtitle),
            value: prefs.arabicNumerals,
            onChanged: (v) =>
                ref.read(appPreferencesProvider.notifier).setArabicNumerals(v),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: l10n.theme),
          _DropdownTile<AppThemePreference>(
            label: l10n.theme,
            value: prefs.theme,
            items: AppThemePreference.values,
            itemLabel: (t) => switch (t) {
              AppThemePreference.system => l10n.themeSystem,
              AppThemePreference.light => l10n.themeLight,
              AppThemePreference.dark => l10n.themeDark,
            },
            onChanged: (t) =>
                ref.read(appPreferencesProvider.notifier).setTheme(t),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: l10n.homeAddress),
          TextField(
            controller: _homeController,
            onChanged: (_) => _homeDirty = true,
            decoration: InputDecoration(
              hintText: l10n.homeAddressHint,
              prefixIcon: const Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                await actions.updateHomeAddress(_homeController.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.saved)),
                  );
                }
              },
              child: Text(l10n.save),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: l10n.notifications),
          ...AppStrings.prayerNames.map((name) {
            final enabled =
                settings?.notificationPrayers.contains(name) ?? true;
            return SwitchListTile(
              title: Text(name),
              value: enabled,
              onChanged: (on) {
                final current = List<String>.from(
                  settings?.notificationPrayers ??
                      AppStrings.prayerNames,
                );
                if (on) {
                  if (!current.contains(name)) current.add(name);
                } else {
                  current.remove(name);
                }
                actions.updateNotificationPrayers(current);
              },
            );
          }),
          const SizedBox(height: 16),
          _SectionHeader(title: l10n.ramadanMode),
          _DropdownTile<RamadanPreference>(
            label: l10n.ramadanMode,
            value: prefs.ramadan,
            items: RamadanPreference.values,
            itemLabel: (r) => switch (r) {
              RamadanPreference.auto => l10n.ramadanAuto,
              RamadanPreference.on => l10n.ramadanOn,
              RamadanPreference.off => l10n.ramadanOff,
            },
            onChanged: (r) =>
                ref.read(appPreferencesProvider.notifier).setRamadan(r),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: l10n.account),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            onTap: actions.signOut,
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            title: Text(
              l10n.deleteAccount,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.deleteAccount),
                  content: Text(l10n.deleteAccountConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await actions.deleteAccount();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _DropdownTile<T> extends StatelessWidget {
  const _DropdownTile({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String Function(T)? itemLabel;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: DropdownButton<T>(
        value: value,
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(itemLabel?.call(item) ?? item.toString()),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
