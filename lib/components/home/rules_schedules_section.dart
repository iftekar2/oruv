import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/models/home_models.dart';
import 'package:oruv/components/home/rule_schedule_card.dart';

class RulesSchedulesSection extends StatelessWidget {
  final List<ScheduleRuleModel> rules;
  final void Function(String ruleId, bool isActive) onRuleToggled;
  final VoidCallback onViewAll;
  final void Function(ScheduleRuleModel rule)? onRuleTap;

  const RulesSchedulesSection({
    super.key,
    required this.rules,
    required this.onRuleToggled,
    required this.onViewAll,
    this.onRuleTap,
  });

  static const Color _primaryText = Color(0xFF1B1B1D);

  @override
  Widget build(BuildContext context) {
    final activeCount = rules.where((r) => r.isActive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: "Rules & Schedules" + "3 Active" pill + "View All >"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
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

        // Rules Cards Row / Horizontal List
        SingleChildScrollView(
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
                child: RuleScheduleCard(
                  rule: rule,
                  width: 238,
                  onToggle: (val) => onRuleToggled(rule.id, val),
                  onTap: onRuleTap != null ? () => onRuleTap!(rule) : null,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

