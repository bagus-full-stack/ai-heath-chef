import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/meal_reminder.dart';
import '../providers/custom_reminders_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../widgets/animated_async_value.dart';
import '../l10n/l10n_extensions.dart';

const Color _kPrimaryColor = Color(0xFF6B66FF);

/// Nom du jour de la semaine dans la langue courante ([weekday] : 1 = lundi
/// ... 7 = dimanche). 2024-01-01 était un lundi, donc `DateTime(2024, 1, weekday)`
/// tombe toujours sur le bon jour — évite d'écrire 7 clés ARB par langue.
String _weekdayName(BuildContext context, int weekday, {bool short = false}) {
  final locale = Localizations.localeOf(context).toString();
  final date = DateTime(2024, 1, weekday);
  return short ? DateFormat.E(locale).format(date) : DateFormat.EEEE(locale).format(date);
}

/// Réglages des rappels : les créneaux fixes (petit-déjeuner/déjeuner/dîner)
/// avec un interrupteur + une heure chacun, et des rappels personnalisés
/// (nom + heure) ajoutés librement par l'utilisateur. Chacun déclenche une
/// notification locale quotidienne.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _openAddReminderSheet(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({String name, int hour, int minute, int? weekday})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddReminderSheet(),
    );
    if (result != null) {
      await ref
          .read(customRemindersProvider.notifier)
          .add(result.name, result.hour, result.minute, weekday: result.weekday);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);
    final customRemindersAsync = ref.watch(customRemindersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.notificationSettingsTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: settingsAsync.animatedWhen(
        loading: () => const Center(child: CircularProgressIndicator(color: _kPrimaryColor)),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(
              context.l10n.notificationSettingsLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
        data: (settings) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              context.l10n.notificationSettingsIntro,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 20),
            for (final slot in MealReminderSlot.values) ...[
              _ReminderTile(
                label: slot.label(context),
                hour: settings[slot]!.hour,
                minute: settings[slot]!.minute,
                enabled: settings[slot]!.enabled,
                onToggle: (value) => ref.read(notificationSettingsProvider.notifier).setEnabled(slot, value),
                onPickTime: (hour, minute) =>
                    ref.read(notificationSettingsProvider.notifier).setTime(slot, hour, minute),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.notificationSettingsCustomRemindersTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.8,
                    color: Colors.grey,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openAddReminderSheet(context, ref),
                  icon: const Icon(Icons.add, size: 18, color: _kPrimaryColor),
                  label: Text(context.l10n.notificationSettingsAddButton, style: const TextStyle(color: _kPrimaryColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            customRemindersAsync.animatedWhen(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: _kPrimaryColor)),
              ),
              error: (error, stackTrace) => Text(
                context.l10n.notificationSettingsCustomRemindersLoadError,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              data: (reminders) {
                if (reminders.isEmpty) {
                  return Text(
                    context.l10n.notificationSettingsNoCustomReminders,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  );
                }
                return Column(
                  children: [
                    for (final reminder in reminders) ...[
                      _ReminderTile(
                        label: reminder.name,
                        hour: reminder.hour,
                        minute: reminder.minute,
                        enabled: reminder.enabled,
                        weekday: reminder.weekday,
                        onToggle: (value) =>
                            ref.read(customRemindersProvider.notifier).setEnabled(reminder.id, value),
                        onPickTime: (hour, minute) =>
                            ref.read(customRemindersProvider.notifier).setTime(reminder.id, hour, minute),
                        onDelete: () => ref.read(customRemindersProvider.notifier).remove(reminder.id),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte réutilisable pour un rappel (créneau fixe ou personnalisé) :
/// icône, nom, heure modifiable, interrupteur, et suppression optionnelle
/// (uniquement pour les rappels personnalisés).
class _ReminderTile extends StatelessWidget {
  final String label;
  final int hour;
  final int minute;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final void Function(int hour, int minute) onPickTime;
  final VoidCallback? onDelete;
  final int? weekday;

  const _ReminderTile({
    required this.label,
    required this.hour,
    required this.minute,
    required this.enabled,
    required this.onToggle,
    required this.onPickTime,
    this.onDelete,
    this.weekday,
  });

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked == null) {
      return;
    }
    onPickTime(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: _kPrimaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: enabled ? () => _pickTime(context) : null,
                  child: Text(
                    enabled
                        ? (weekday != null
                            ? context.l10n.notificationSettingsReminderWeeklyAtLabel(_weekdayName(context, weekday!), timeLabel)
                            : context.l10n.notificationSettingsReminderAtLabel(timeLabel))
                        : context.l10n.notificationSettingsDisabledLabel,
                    style: TextStyle(
                      color: enabled ? _kPrimaryColor : Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            activeThumbColor: _kPrimaryColor,
            onChanged: onToggle,
          ),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

/// Formulaire d'ajout d'un rappel personnalisé : nom + heure.
class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _nameController = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _isWeekly = false;
  int _weekday = DateTime.monday;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.notificationSettingsNameRequiredError), backgroundColor: Colors.redAccent),
      );
      return;
    }
    Navigator.of(context).pop((
      name: name,
      hour: _time.hour,
      minute: _time.minute,
      weekday: _isWeekly ? _weekday : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Text(context.l10n.notificationSettingsNewReminderTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.notificationSettingsReminderNameLabel,
                hintText: context.l10n.notificationSettingsReminderNameHint,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: _kPrimaryColor),
                    const SizedBox(width: 10),
                    Text(
                      context.l10n.notificationSettingsTimeLabel(
                        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(context.l10n.notificationSettingsFrequencyDaily),
                    selected: !_isWeekly,
                    selectedColor: _kPrimaryColor.withValues(alpha: 0.15),
                    onSelected: (_) => setState(() => _isWeekly = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: Text(context.l10n.notificationSettingsFrequencyWeekly),
                    selected: _isWeekly,
                    selectedColor: _kPrimaryColor.withValues(alpha: 0.15),
                    onSelected: (_) => setState(() => _isWeekly = true),
                  ),
                ),
              ],
            ),
            if (_isWeekly) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                    ChoiceChip(
                      label: Text(_weekdayName(context, day, short: true)),
                      selected: _weekday == day,
                      selectedColor: _kPrimaryColor.withValues(alpha: 0.15),
                      onSelected: (_) => setState(() => _weekday = day),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                context.l10n.notificationSettingsAddSubmitButton,
                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
