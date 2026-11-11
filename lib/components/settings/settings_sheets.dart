import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

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

class MyAccountSheet extends StatefulWidget {
  final String email;
  final String providerLabel;
  final bool isEmailProvider;
  final Future<void> Function(String fullName, int? age) onSaveProfile;
  final Future<void> Function() onResetPassword;
  final VoidCallback onRequestSignOut;

  const MyAccountSheet({
    super.key,
    required this.email,
    required this.providerLabel,
    required this.isEmailProvider,
    required this.onSaveProfile,
    required this.onResetPassword,
    required this.onRequestSignOut,
  });

  @override
  State<MyAccountSheet> createState() => _MyAccountSheetState();
}

class _MyAccountSheetState extends State<MyAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  bool _isSaving = false;
  bool _isSendingReset = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: OnboardingData.instance.fullName,
    );
    _ageController = TextEditingController(
      text: OnboardingData.instance.age?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final parsedAge = int.tryParse(_ageController.text.trim());
      await widget.onSaveProfile(_nameController.text.trim(), parsedAge);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handlePasswordReset() async {
    setState(() => _isSendingReset = true);
    try {
      await widget.onResetPassword();
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.lora(
        fontSize: 14,
        color: SettingsPalette.mutedText.withValues(alpha: 0.7),
      ),
      filled: true,
      fillColor: SettingsPalette.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SettingsPalette.cardBorder),
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
        borderSide: const BorderSide(color: SettingsPalette.coralRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: SettingsPalette.coralRed,
          width: 1.5,
        ),
      ),
    );
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
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: SettingsPalette.softMint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: SettingsPalette.accentGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Account',
                            style: GoogleFonts.lora(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: SettingsPalette.primaryText,
                            ),
                          ),
                          Text(
                            'Manage your profile & sign-in details',
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
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: SettingsPalette.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: SettingsPalette.accentGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.email,
                          style: GoogleFonts.lora(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: SettingsPalette.primaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: SettingsPalette.softMint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.providerLabel,
                          style: GoogleFonts.lora(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: SettingsPalette.accentGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'FULL NAME',
                  style: GoogleFonts.lora(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: SettingsPalette.mutedText,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    color: SettingsPalette.primaryText,
                  ),
                  decoration: _fieldDecoration('Enter your name'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'AGE (OPTIONAL)',
                  style: GoogleFonts.lora(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: SettingsPalette.mutedText,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    color: SettingsPalette.primaryText,
                  ),
                  decoration: _fieldDecoration('Your age'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    final age = int.tryParse(val.trim());
                    if (age == null || age < 10 || age > 120) {
                      return 'Enter a valid age';
                    }
                    return null;
                  },
                ),
                if (widget.isEmailProvider) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSendingReset ? null : _handlePasswordReset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SettingsPalette.primaryText,
                        side: const BorderSide(
                          color: SettingsPalette.cardBorder,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: _isSendingReset
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_reset_rounded, size: 19),
                      label: Text(
                        'Send Password Reset Email',
                        style: GoogleFonts.lora(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SettingsPalette.darkButton,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.lora(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onRequestSignOut();
                    },
                    child: Text(
                      'Log Out of Account',
                      style: GoogleFonts.lora(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: SettingsPalette.coralRed,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
              const _SheetHandle(),
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

String resolveAuthProviderLabel(User? user) {
  final raw = user?.appMetadata['provider']?.toString().toLowerCase() ?? '';
  if (raw == 'google') return 'Google';
  if (raw == 'apple') return 'Apple';
  return 'Email';
}
