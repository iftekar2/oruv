import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/models/home_models.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';

class RuleEditorSheet extends StatefulWidget {
  final ScheduleRuleModel? existingRule;
  final ValueChanged<ScheduleRuleModel> onSave;
  final VoidCallback? onDelete;

  const RuleEditorSheet({
    super.key,
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

  static const Color _accentGreen = Color(0xFF1D6F58);
  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFECE8E4);

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

  void _handleSave() {
    final title = _titleController.text.trim().isEmpty
        ? 'Focus Schedule'
        : _titleController.text.trim();

    final nativeCount = OnboardingData.instance.totalSelectedAppsCount;
    final finalBlockedCount = nativeCount > 0
        ? nativeCount
        : _extraBlockedCount;

    final updatedRule = ScheduleRuleModel(
      id:
          widget.existingRule?.id ??
          'rule_${DateTime.now().millisecondsSinceEpoch}',
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
                      // 1. Prominent Choose from All iPhone Apps & Categories Card
                      Text(
                        'SHIELDED APPS',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: _mutedText,
                        ),
                      ),

                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _openNativeScreenTimePicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3EFEA),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.apps_rounded,
                                      size: 22,
                                      color: _primaryText,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Choose from All iPhone Apps & Categories',
                                          style: GoogleFonts.lora(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            height: 1.25,
                                            color: _primaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _extraBlockedCount > 0
                                              ? 'Tap to add or remove blocked apps'
                                              : 'Tap to select apps & websites to block',
                                          style: GoogleFonts.lora(
                                            fontSize: 12,
                                            color: _mutedText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 22,
                                    color: _mutedText,
                                  ),
                                ],
                              ),
                              if (_extraBlockedCount > 0) ...[
                                const SizedBox(height: 14),
                                const Divider(
                                  color: Color(0xFFF2EEEA),
                                  height: 1,
                                  thickness: 1,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 28,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: _accentGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '$_extraBlockedCount ${_extraBlockedCount == 1 ? 'App' : 'Apps'} chosen to block',
                                          style: GoogleFonts.lora(
                                            fontSize: 13,
                                            height: 1.1,
                                            fontWeight: FontWeight.w600,
                                            color: _primaryText,
                                          ),
                                        ),
                                      ),
                                      if (Platform.isIOS && !_isPickerOpen)
                                        ClipRect(
                                          child: SizedBox(
                                            width: 110,
                                            height: 28,
                                            child: IgnorePointer(
                                              child: UiKitView(
                                                key: ValueKey<int>(
                                                  _extraBlockedCount,
                                                ),
                                                viewType:
                                                    'oruv/selected_apps_icons',
                                                creationParamsCodec:
                                                    const StandardMessageCodec(),
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (Platform.isIOS)
                                        const SizedBox(width: 110, height: 28),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 22),

                    // 2. Schedule Name Input + Quick Presets
                    Text(
                      'SCHEDULE NAME',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: _mutedText,
                      ),
                    ),

                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.lora(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: _primaryText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Work Time, Study Block',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: _accentGreen,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _presetNames.map((preset) {
                          final isMatch = _titleController.text == preset;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _titleController.text = preset;
                                });
                              },

                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isMatch
                                      ? const Color(0xFFE6F5F0)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isMatch ? _accentGreen : _cardBorder,
                                  ),
                                ),

                                child: Text(
                                  preset,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isMatch ? _accentGreen : _mutedText,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3. Time Block (Start & End Time)
                    Text(
                      'TIME BLOCK',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: _mutedText,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickTime(isStart: true),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'STARTS',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _mutedText,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 15,
                                        color: _accentGreen,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _startTime,
                                    style: GoogleFonts.lora(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w700,
                                      color: _primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickTime(isStart: false),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'UNLOCKS',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _mutedText,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 15,
                                        color: _accentGreen,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _endTime,
                                    style: GoogleFonts.lora(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w700,
                                      color: _primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 4. Active Days
                    Text(
                      'ACTIVE DAYS',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: _mutedText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_dayKeys.length, (idx) {
                        final key = _dayKeys[idx];
                        final label = _dayLabels[idx];
                        final isSelected = _activeDays.contains(key);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected && _activeDays.length > 1) {
                                _activeDays.remove(key);
                              } else {
                                _activeDays.add(key);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFF131B26)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF131B26)
                                    : _cardBorder,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              label,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : _mutedText,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),

                    // 5. Enforcement Mode
                    Text(
                      'ENFORCEMENT MODE',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: _mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: _enforcementOptions.map((mode) {
                        final isSelected = _enforcementMode == mode;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _enforcementMode = mode),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? _accentGreen
                                      : _cardBorder,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    size: 18,
                                    color: isSelected
                                        ? _accentGreen
                                        : _mutedText,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      mode,
                                      style: GoogleFonts.lora(
                                        fontSize: 13.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _primaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF131B26),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'Save Changes' : 'Create Schedule',
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
