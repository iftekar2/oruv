import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPalette {
  static const Color background = Color(0xFFFDFCF9);
  static const Color card = Colors.white;
  static const Color cardBorder = Color(0xFFECE8E4);
  static const Color divider = Color(0xFFF2EEEA);
  static const Color primaryText = Color(0xFF1B1B1D);
  static const Color mutedText = Color(0xFF6E6A6E);
  static const Color accentGreen = Color(0xFF1D6F58);
  static const Color softMint = Color(0xFFE6F5F0);
  static const Color avatarBg = Color(0xFFF4F0EB);
  static const Color darkButton = Color(0xFF131B26);
  static const Color coralRed = Color(0xFFD94841);
  static const Color softCoral = Color(0xFFFFF4F3);
}

class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFDDD8D2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class SettingsGroupedCard extends StatelessWidget {
  final List<Widget> children;
  final Color? backgroundColor;
  final Color? borderColor;

  const SettingsGroupedCard({
    super.key,
    required this.children,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? SettingsPalette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? SettingsPalette.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 56, right: 16),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: SettingsPalette.divider,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final String? trailingText;
  final Color? trailingColor;
  final bool showChevron;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailingText,
    this.trailingColor,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else if (icon != null)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: SettingsPalette.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: SettingsPalette.cardBorder.withValues(alpha: 0.8),
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: titleColor ?? SettingsPalette.primaryText.withValues(alpha: 0.82),
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? SettingsPalette.primaryText,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lora(
                      fontSize: 12.5,
                      color: SettingsPalette.mutedText,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingText != null) ...[
            const SizedBox(width: 10),
            Text(
              trailingText!,
              style: GoogleFonts.lora(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: trailingColor ?? SettingsPalette.mutedText,
              ),
            ),
          ],
          if (showChevron) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: SettingsPalette.mutedText.withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

class OptionPickerItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;

  const OptionPickerItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
  });
}

const List<OptionPickerItem<String>> kScreenTimeGoalOptions = [
  OptionPickerItem(
    value: '< 2 hours',
    title: 'Under 2 hours',
    subtitle: 'Minimalist daily digital footprint',
    icon: Icons.bolt_rounded,
  ),
  OptionPickerItem(
    value: '3 - 4 hours',
    title: '3 - 4 hours',
    subtitle: 'Balanced focus and intentional rest',
    icon: Icons.balance_rounded,
  ),
  OptionPickerItem(
    value: '5 - 6 hours',
    title: '5 - 6 hours',
    subtitle: 'Steady transition away from heavy use',
    icon: Icons.trending_down_rounded,
  ),
  OptionPickerItem(
    value: '7+ hours',
    title: '7+ hours',
    subtitle: 'High-baseline tracking for gradual cutbacks',
    icon: Icons.timelapse_rounded,
  ),
];

Future<T?> showSettingsOptionSheet<T>({
  required BuildContext context,
  required String title,
  required String subtitle,
  required IconData headerIcon,
  required List<OptionPickerItem<T>> options,
  required T currentValue,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        decoration: const BoxDecoration(
          color: SettingsPalette.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: SettingsPalette.softMint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      headerIcon,
                      color: SettingsPalette.accentGreen,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.lora(
                            fontSize: 19.5,
                            fontWeight: FontWeight.w700,
                            color: SettingsPalette.primaryText,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.lora(
                            fontSize: 12.5,
                            color: SettingsPalette.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...options.map((item) {
                final isSelected = item.value == currentValue;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.pop(sheetContext, item.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? SettingsPalette.accentGreen
                                : SettingsPalette.cardBorder,
                            width: isSelected ? 1.6 : 1.1,
                          ),
                          color: isSelected
                              ? SettingsPalette.softMint.withValues(alpha: 0.35)
                              : Colors.white,
                        ),
                        child: Row(
                          children: [
                            if (item.icon != null) ...[
                              Icon(
                                item.icon,
                                size: 20,
                                color: isSelected
                                    ? SettingsPalette.accentGreen
                                    : SettingsPalette.mutedText,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: GoogleFonts.lora(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: SettingsPalette.primaryText,
                                    ),
                                  ),
                                  if (item.subtitle != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.subtitle!,
                                      style: GoogleFonts.lora(
                                        fontSize: 12,
                                        color: SettingsPalette.mutedText,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: SettingsPalette.accentGreen,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

Future<String?> showTextInputSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required IconData headerIcon,
  required String initialValue,
  required String hintText,
  TextInputType keyboardType = TextInputType.text,
  TextCapitalization textCapitalization = TextCapitalization.words,
  String? Function(String?)? validator,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _TextInputSheetBody(
        title: title,
        subtitle: subtitle,
        headerIcon: headerIcon,
        initialValue: initialValue,
        hintText: hintText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
      );
    },
  );
}

class _TextInputSheetBody extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData headerIcon;
  final String initialValue;
  final String hintText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _TextInputSheetBody({
    required this.title,
    required this.subtitle,
    required this.headerIcon,
    required this.initialValue,
    required this.hintText,
    required this.keyboardType,
    required this.textCapitalization,
    this.validator,
  });

  @override
  State<_TextInputSheetBody> createState() => _TextInputSheetBodyState();
}

class _TextInputSheetBodyState extends State<_TextInputSheetBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? true)) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: SettingsPalette.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: SettingsPalette.softMint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.headerIcon,
                      color: SettingsPalette.accentGreen,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.lora(
                            fontSize: 19.5,
                            fontWeight: FontWeight.w700,
                            color: SettingsPalette.primaryText,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: GoogleFonts.lora(
                            fontSize: 12.5,
                            color: SettingsPalette.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _controller,
                autofocus: true,
                keyboardType: widget.keyboardType,
                textCapitalization: widget.textCapitalization,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                style: GoogleFonts.lora(
                  fontSize: 15,
                  color: SettingsPalette.primaryText,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: GoogleFonts.lora(
                    fontSize: 14.5,
                    color: SettingsPalette.mutedText.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: SettingsPalette.cardBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: SettingsPalette.accentGreen,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: SettingsPalette.coralRed,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: SettingsPalette.coralRed,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: widget.validator,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SettingsPalette.darkButton,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    'Save',
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
    );
  }
}

String resolveAuthProviderLabel(User? user) {
  final raw = user?.appMetadata['provider']?.toString().toLowerCase() ?? '';
  if (raw == 'google') return 'Google';
  if (raw == 'apple') return 'Apple';
  return 'Email';
}
