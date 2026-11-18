import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/models/home_models.dart';
import 'package:oruv/components/home/rule_editor/rule_editor_apps_selector.dart';
import 'package:oruv/components/home/rule_editor/rule_editor_conflict_banner.dart';
import 'package:oruv/components/home/rule_editor/rule_editor_days_selector.dart';
import 'package:oruv/components/home/rule_editor/rule_editor_mode_selector.dart';
import 'package:oruv/components/home/rule_editor/rule_editor_time_picker.dart';
import 'package:oruv/components/home/rule_editor/rule_editor_title_section.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';

class RuleEditorSheet extends StatefulWidget {
  final List<ScheduleRuleModel> existingRules;
  final ScheduleRuleModel? existingRule;
  final ValueChanged<ScheduleRuleModel> onSave;
  final VoidCallback? onDelete;

  const RuleEditorSheet({
    super.key,
    this.existingRules = const [],
    this.existingRule,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends State<RuleEditorSheet> {
  late TextEditingController _titleController;
  late String _startTime;
  late String _endTime;
  late String _enforcementMode;
  late Set<String> _activeDays;
  late int _extraBlockedCount;
  bool _isPickerOpen = false;

  final List<String> _dayKeys = ['M', 'T', 'W', 'T2', 'F', 'S', 'S2'];
  final List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  final List<String> _enforcementOptions = [
    'Strict enforcement mode',
    'Balanced enforcement mode',
    'Gentle reminder mode',
  ];

  final List<String> _presetNames = [
    'Work Time',
    'Study Focus',
    'Evening Wind Down',
    'Morning Clarity',
    'Weekend Detox',
  ];

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);

  @override
  void initState() {
    super.initState();
    final rule = widget.existingRule;
    _titleController = TextEditingController(
      text: rule?.title ?? 'Deep Focus Block',
    );
    _startTime = rule?.startTime ?? '9:00 AM';
    _endTime = rule?.endTime ?? '5:00 PM';
    _enforcementMode = rule?.enforcementMode ?? 'Strict enforcement mode';
    _activeDays = Set<String>.from(
      rule?.activeDays ?? {'M', 'T', 'W', 'T2', 'F'},
    );
    final nativeTotal = OnboardingData.instance.totalSelectedAppsCount;
    _extraBlockedCount = nativeTotal > 0
        ? nativeTotal
        : (rule?.blockedCount ?? 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String formatted, TimeOfDay fallback) {
    try {
      final clean = formatted.trim().toUpperCase();
      final isPM = clean.contains('PM');
      final isAM = clean.contains('AM');
      final parts = clean
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim()
          .split(':');
      if (parts.length == 2) {
        int hour = int.parse(parts[0].trim());
        final int minute = int.parse(parts[1].trim());
        if (isPM && hour < 12) hour += 12;
        if (isAM && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return fallback;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? _parseTime(_startTime, const TimeOfDay(hour: 9, minute: 0))
        : _parseTime(_endTime, const TimeOfDay(hour: 17, minute: 0));

    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked != null && mounted) {
      setState(() {
        final formatted = picked.format(context);
        if (isStart) {
          _startTime = formatted;
        } else {
          _endTime = formatted;
        }
      });
    }
  }

  Future<void> _openNativeScreenTimePicker() async {
    setState(() {
      _isPickerOpen = true;
    });

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.75,
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select iPhone Apps to Block',
                        style: GoogleFonts.lora(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Done',
                          style: GoogleFonts.lora(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Platform.isIOS
                      ? const UiKitView(
                          viewType: 'oruv/family_activity_picker',
                          creationParamsCodec: StandardMessageCodec(),
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'Apple Screen Time picker is available on iOS devices.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lora(color: Colors.white70),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (mounted) {
      setState(() {
        _isPickerOpen = false;
        _extraBlockedCount = OnboardingData.instance.totalSelectedAppsCount;
      });
    }
  }

  String _generateUniqueRuleId() {
    final random = Random.secure();
    final suffix = List.generate(
      8,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return 'rule_${DateTime.now().millisecondsSinceEpoch}_$suffix';
  }

  ScheduleRuleModel? get _conflictingRule {
    return ScheduleRuleModel.findConflictingSchedule(
      startTime: _startTime,
      endTime: _endTime,
      activeDays: _activeDays.isEmpty
          ? {'M', 'T', 'W', 'T2', 'F'}
          : _activeDays,
      existingRules: widget.existingRules,
      excludeRuleId: widget.existingRule?.id,
    );
  }

  void _handleSave() {
    final conflict = _conflictingRule;
    if (conflict != null) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot save: overlaps with "${conflict.title}" (${conflict.timeRange}).',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? 'Focus Schedule'
        : _titleController.text.trim();

    final nativeCount = OnboardingData.instance.totalSelectedAppsCount;
    final finalBlockedCount = nativeCount > 0
        ? nativeCount
        : _extraBlockedCount;

    final updatedRule = ScheduleRuleModel(
      id: widget.existingRule?.id ?? _generateUniqueRuleId(),
      title: title,
      startTime: _startTime,
      endTime: _endTime,
      enforcementMode: _enforcementMode,
      isActive: widget.existingRule?.isActive ?? true,
      activeDays: _activeDays.isEmpty
          ? {'M', 'T', 'W', 'T2', 'F'}
          : _activeDays,
      selectedAppIds: const {},
      extraBlockedCount: finalBlockedCount,
    );

    Navigator.pop(context);
    widget.onSave(updatedRule);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRule != null;
    final conflict = _conflictingRule;
    final hasConflict = conflict != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFCF9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDD8D2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Schedule' : 'New Block Schedule',
                          style: GoogleFonts.lora(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: _primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Customize block time, active days, and shielded apps',
                          style: GoogleFonts.lora(
                            fontSize: 12.5,
                            color: _mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEditing && widget.onDelete != null)
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onDelete!();
                      },
                      tooltip: 'Delete Schedule',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFD92B2B),
                      ),
                    ),
                ],
              ),
            ),

            // Scrollable Form Body
            Flexible(
              child: ClipRect(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Choose from All iPhone Apps & Categories
                      RuleEditorAppsSelector(
                        extraBlockedCount: _extraBlockedCount,
                        isPickerOpen: _isPickerOpen,
                        onTap: _openNativeScreenTimePicker,
                      ),

                      const SizedBox(height: 22),

                      // 2. Schedule Name Input + Quick Presets
                      RuleEditorTitleSection(
                        controller: _titleController,
                        presetNames: _presetNames,
                        onPresetSelected: (preset) {
                          setState(() {
                            _titleController.text = preset;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      // 3. Time Block (Start & End Time)
                      RuleEditorTimePicker(
                        startTime: _startTime,
                        endTime: _endTime,
                        onPickTime: _pickTime,
                      ),

                      const SizedBox(height: 20),

                      // 4. Active Days
                      RuleEditorDaysSelector(
                        dayKeys: _dayKeys,
                        dayLabels: _dayLabels,
                        activeDays: _activeDays,
                        onDayToggled: (key) {
                          setState(() {
                            if (_activeDays.contains(key) &&
                                _activeDays.length > 1) {
                              _activeDays.remove(key);
                            } else {
                              _activeDays.add(key);
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      // 5. Enforcement Mode
                      RuleEditorModeSelector(
                        options: _enforcementOptions,
                        selectedMode: _enforcementMode,
                        onModeSelected: (mode) {
                          setState(() => _enforcementMode = mode);
                        },
                      ),

                      if (hasConflict) ...[
                        const SizedBox(height: 16),
                        RuleEditorConflictBanner(conflict: conflict),
                      ],

                      const SizedBox(height: 16),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: hasConflict ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF131B26),
                            disabledBackgroundColor: const Color(0xFFD6D1CB),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: const Color(0xFF8A8580),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            hasConflict
                                ? 'Time Slot Overlaps'
                                : (isEditing
                                      ? 'Save Changes'
                                      : 'Create Schedule'),
                            style: GoogleFonts.lora(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
