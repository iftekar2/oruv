import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/models/home_models.dart';
import 'package:oruv/components/home/rule_schedule_card.dart';

class RulesSchedulesSection extends StatelessWidget {
  final List<ScheduleRuleModel> rules;
  final void Function(String ruleId, bool isActive) onRuleToggled;
  final void Function(ScheduleRuleModel rule) onRuleTap;
  final VoidCallback? onAddRule;
  final VoidCallback? onViewAll;
  final bool isGrid;

  const RulesSchedulesSection({
    super.key,
    required this.rules,
    required this.onRuleToggled,
    required this.onRuleTap,
    this.onAddRule,
    this.onViewAll,
    this.isGrid = false,
  });

  static const Color _primaryText = Color(0xFF1B1B1D);

  @override
  Widget build(BuildContext context) {
    final activeCount = rules.where((r) => r.isActive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: "Rules & Schedules" + "X Active" pill + optional "View All >"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Row(
            children: [
              Text(
                'Rules & Schedules',
                style: GoogleFonts.lora(
                  fontSize: 19.5,
                  fontWeight: FontWeight.w700,
                  color: _primaryText,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEECE9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$activeCount Active',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2B2628),
                  ),
                ),
              ),
              const Spacer(),
              if (!isGrid && onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: GoogleFonts.lora(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _primaryText,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: _primaryText,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (isGrid) _buildTwoColumnGrid() else _buildHorizontalRow(),
      ],
    );
  }

  /// Horizontal scrolling row for the Home Page (without "New Schedule")
  Widget _buildHorizontalRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(rules.length, (index) {
          final rule = rules[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == rules.length - 1 ? 0 : 14,
            ),
            child: RepaintBoundary(
              child: RuleScheduleCard(
                rule: rule,
                width: 234,
                onToggle: (val) => onRuleToggled(rule.id, val),
                onTap: () => onRuleTap(rule),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 2-Column stacked grid for the Shields Page with "New Schedule" first
  Widget _buildTwoColumnGrid() {
    final List<Widget> gridWidgets = [
      if (onAddRule != null) AddScheduleGridCard(onTap: onAddRule!),
      ...rules.map(
        (rule) => RuleScheduleCard(
          rule: rule,
          onToggle: (val) => onRuleToggled(rule.id, val),
          onTap: () => onRuleTap(rule),
        ),
      ),
    ];

    final List<Widget> rows = [];
    for (int i = 0; i < gridWidgets.length; i += 2) {
      final first = gridWidgets[i];
      final second =
          (i + 1 < gridWidgets.length) ? gridWidgets[i + 1] : null;

      rows.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i + 2 < gridWidgets.length ? 12.0 : 0.0,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: first),
                const SizedBox(width: 12),
                Expanded(
                  child: second ?? const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}
