import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/models/home_models.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';

class AdjustAnchorSheet extends StatefulWidget {
  final String initialStartTime;
  final String initialEndTime;
  final bool initialStrictLock;
  final List<ScheduleRuleModel> existingRules;
  final String? targetRuleId;
  final Set<String> activeDays;
  final void Function(String startTime, String endTime, bool strictLock)
      onSave;

  const AdjustAnchorSheet({
    super.key,
    required this.initialStartTime,
    required this.initialEndTime,
    required this.initialStrictLock,
    required this.onSave,
    this.existingRules = const [],
    this.targetRuleId,
    this.activeDays = const {'M', 'T', 'W', 'T2', 'F'},
  });

  @override
  State<AdjustAnchorSheet> createState() => _AdjustAnchorSheetState();
}

class _AdjustAnchorSheetState extends State<AdjustAnchorSheet> {
  late String _startTime;
  late String _endTime;
  late bool _strictLock;
  bool _isPickerOpen = false;

  static const Color _accentGreen = Color(0xFF1D6F58);
  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFECE8E4);

  ScheduleRuleModel? get _conflictingRule {
    return ScheduleRuleModel.findConflictingSchedule(
      startTime: _startTime,
      endTime: _endTime,
      activeDays: widget.activeDays,
      existingRules: widget.existingRules,
      excludeRuleId: widget.targetRuleId,
    );
  }

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
    _strictLock = widget.initialStrictLock;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? const TimeOfDay(hour: 9, minute: 0)
          : const TimeOfDay(hour: 17, minute: 0),
    );
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

  Future<void> _openAppShieldPicker() async {
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shielded Apps',
                        style: GoogleFonts.lora(
                          fontSize: 18,
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
                          child: Text(
                            'Apple Screen Time picker is available on iOS devices.',
                            style: GoogleFonts.lora(color: Colors.white70),
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = OnboardingData.instance.totalSelectedAppsCount;
    final conflict = _conflictingRule;
    final hasConflict = conflict != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFCF9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDD8D2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Adjust Deep Work Anchor',
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Customize your active focus schedule and shielded apps',
              style: GoogleFonts.lora(
                fontSize: 13,
                color: _mutedText,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(isStart: true),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STARTS',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _mutedText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startTime,
                                style: GoogleFonts.lora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryText,
                                ),
                              ),
                              const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: _mutedText,
                              ),
                            ],
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
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ENDS',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _mutedText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _endTime,
                                style: GoogleFonts.lora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryText,
                                ),
                              ),
                              const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: _mutedText,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Manage Locked / Unblocked Apps Row
            GestureDetector(
              onTap: _openAppShieldPicker,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EFEA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.apps_rounded,
                            size: 20,
                            color: _primaryText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose from All iPhone Apps & Categories',
                                style: GoogleFonts.lora(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryText,
                                ),
                              ),
                              Text(
                                selectedCount > 0
                                    ? 'Tap to add or remove blocked apps'
                                    : 'Tap to lock or unblock apps',
                                style: GoogleFonts.lora(
                                  fontSize: 11.5,
                                  color: _mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: _mutedText,
                        ),
                      ],
                    ),
                    if (selectedCount > 0) ...[
                      const SizedBox(height: 12),
                      const Divider(
                        color: Color(0xFFF2EEEA),
                        height: 1,
                        thickness: 1,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 28,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                '$selectedCount ${selectedCount == 1 ? 'App' : 'Apps'} chosen to block',
                                style: GoogleFonts.lora(
                                  fontSize: 12.5,
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
                                      key: ValueKey<int>(selectedCount),
                                      viewType: 'oruv/selected_apps_icons',
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

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: _accentGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Strict Enforcement Mode',
                          style: GoogleFonts.lora(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _primaryText,
                          ),
                        ),
                        Text(
                          'Require mindful countdown before unblocking',
                          style: GoogleFonts.lora(
                            fontSize: 11.5,
                            color: _mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _strictLock,
                    activeColor: _accentGreen,
                    onChanged: (val) => setState(() => _strictLock = val),
                  ),
                ],
              ),
            ),
            if (hasConflict) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF3E7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE89A58).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: Color(0xFFC06A28),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule Conflict',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8A4612),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'This time overlaps with "${conflict!.title}" (${conflict.timeRange}). Please pick another time.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8A4612).withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: hasConflict
                    ? null
                    : () {
                        Navigator.pop(context);
                        widget.onSave(_startTime, _endTime, _strictLock);
                      },
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
                  hasConflict ? 'Time Slot Overlaps' : 'Save Anchor Schedule',
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
    );
  }
}
