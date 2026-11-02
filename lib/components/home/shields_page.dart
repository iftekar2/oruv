import 'package:flutter/material.dart';
import 'package:oruv/components/home/models/home_models.dart';
import 'package:oruv/components/home/rules_schedules_section.dart';

class ShieldsPage extends StatelessWidget {
  final List<ScheduleRuleModel> rules;
  final void Function(String ruleId, bool isActive) onRuleToggled;
  final void Function(ScheduleRuleModel rule) onEditRule;
  final VoidCallback onAddRule;

  const ShieldsPage({
    super.key,
    required this.rules,
    required this.onRuleToggled,
    required this.onEditRule,
    required this.onAddRule,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      child: RulesSchedulesSection(
        rules: rules,
        onRuleToggled: onRuleToggled,
        onRuleTap: onEditRule,
        onAddRule: onAddRule,
        isGrid: true,
      ),
    );
  }
}
