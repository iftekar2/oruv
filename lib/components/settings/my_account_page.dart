import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';
import 'package:oruv/components/onboarding/onboarding_service.dart';
import 'package:oruv/components/settings/settings_sheets.dart';
import 'package:oruv/components/welcomePages/screenFour.dart';
import 'package:oruv/services/account_lifecycle_service.dart';
import 'package:oruv/services/auth_redirect_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  bool _isBusy = false;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.lora(fontSize: 13.5, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? SettingsPalette.coralRed
            : SettingsPalette.accentGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _editName() async {
    final result = await showTextInputSheet(
      context: context,
      title: 'Your Name',
      subtitle: 'Displayed across your Oruv profile',
      headerIcon: Icons.person_rounded,
      initialValue: OnboardingData.instance.fullName,
      hintText: 'Enter your name',
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
    if (result == null || result == OnboardingData.instance.fullName) return;
    setState(() => OnboardingData.instance.fullName = result);
    await OnboardingService.saveOnboardingData();
    _showSnackBar('Name updated');
  }

  Future<void> _editOccupation() async {
    final result = await showTextInputSheet(
      context: context,
      title: 'Occupation',
      subtitle: 'Helps personalize your focus context',
      headerIcon: Icons.work_rounded,
      initialValue: OnboardingData.instance.occupation,
      hintText: 'e.g. Software Development, Student',
    );
    if (result == null || result == OnboardingData.instance.occupation) return;
    setState(() => OnboardingData.instance.occupation = result);
    await OnboardingService.saveOnboardingData();
    _showSnackBar(
      result.isEmpty ? 'Occupation cleared' : 'Occupation updated',
    );
  }

  Future<void> _editAge() async {
    final result = await showTextInputSheet(
      context: context,
      title: 'My Age',
      subtitle: 'Used to tailor your focus benchmarks',
      headerIcon: Icons.cake_rounded,
      initialValue: OnboardingData.instance.age?.toString() ?? '',
      hintText: 'Enter your age',
      keyboardType: TextInputType.number,
      textCapitalization: TextCapitalization.none,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return null;
        final age = int.tryParse(val.trim());
        if (age == null || age < 10 || age > 120) {
          return 'Enter a valid age (10–120)';
        }
        return null;
      },
    );
    if (result == null) return;
    final parsed = result.isEmpty ? null : int.tryParse(result);
    if (parsed == OnboardingData.instance.age) return;
    setState(() => OnboardingData.instance.age = parsed);
    await OnboardingService.saveOnboardingData();
    _showSnackBar(parsed == null ? 'Age cleared' : 'Age updated');
  }

  Future<void> _editOriginalScreenTime() async {
    final selected = await showSettingsOptionSheet<String>(
      context: context,
      title: 'Original Screen Time',
      subtitle: 'Your daily baseline before using Oruv',
      headerIcon: Icons.hourglass_bottom_rounded,
      options: kScreenTimeGoalOptions,
      currentValue: OnboardingData.instance.dailyScreenTime,
    );
    if (selected == null ||
        selected == OnboardingData.instance.dailyScreenTime) {
      return;
    }
    setState(() => OnboardingData.instance.dailyScreenTime = selected);
    await OnboardingService.saveOnboardingData();
    _showSnackBar('Baseline screen time updated');
  }

  Future<void> _openEmailSheet(User? user, String providerLabel) async {
    final email = user?.email ?? '';
    final isEmailProvider = providerLabel == 'Email';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
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
                      child: const Icon(
                        Icons.email_rounded,
                        color: SettingsPalette.accentGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Email',
                            style: GoogleFonts.lora(
                              fontSize: 19.5,
                              fontWeight: FontWeight.w700,
                              color: SettingsPalette.primaryText,
                            ),
                          ),
                          Text(
                            email.isNotEmpty ? email : 'No email attached',
                            style: GoogleFonts.lora(
                              fontSize: 13,
                              color: SettingsPalette.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SettingsPalette.cardBorder),
                  ),
                  child: Text(
                    isEmailProvider
                        ? 'You sign in with your email and password.'
                        : 'Managed via your $providerLabel account.',
                    style: GoogleFonts.lora(
                      fontSize: 13.5,
                      color: SettingsPalette.mutedText,
                    ),
                  ),
                ),
                if (isEmailProvider && email.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        try {
                          await AuthRedirectService.markPendingFlow(
                            AuthRedirectFlow.resetPassword,
                            userId: Supabase.instance.client.auth.currentUser?.id,
                          );
                          await Supabase.instance.client.auth
                              .resetPasswordForEmail(
                                email,
                                redirectTo:
                                    AuthRedirectService.resetPasswordRedirectUrl,
                              );
                          _showSnackBar('Password reset email sent to $email');
                        } catch (_) {
                          await AuthRedirectService.clearPendingFlow(
                            AuthRedirectFlow.resetPassword,
                          );
                          _showSnackBar(
                            'Could not send password reset email',
                            isError: true,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SettingsPalette.darkButton,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      icon: const Icon(Icons.lock_reset_rounded, size: 19),
                      label: Text(
                        'Send Password Reset Email',
                        style: GoogleFonts.lora(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SettingsPalette.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Sign out of Oruv?',
          style: GoogleFonts.lora(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: SettingsPalette.primaryText,
          ),
        ),
        content: Text(
          'Your schedules and focus preferences stay safely saved to your account.',
          style: GoogleFonts.lora(
            fontSize: 13.5,
            color: SettingsPalette.mutedText,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.lora(
                fontWeight: FontWeight.w600,
                color: SettingsPalette.mutedText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SettingsPalette.darkButton,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Sign out',
              style: GoogleFonts.lora(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      await AccountLifecycleService.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ScreenFour()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmController = TextEditingController();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isReady =
                confirmController.text.trim().toUpperCase() == 'DELETE';
            return AlertDialog(
              backgroundColor: SettingsPalette.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'Delete My Account',
                style: GoogleFonts.lora(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: SettingsPalette.coralRed,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This permanently deletes your profile, focus schedules, and saved preferences. This action cannot be undone.',
                    style: GoogleFonts.lora(
                      fontSize: 13.5,
                      color: SettingsPalette.mutedText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Type DELETE to confirm:',
                    style: GoogleFonts.lora(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: SettingsPalette.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setDialogState(() {}),
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      color: SettingsPalette.primaryText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'DELETE',
                      hintStyle: GoogleFonts.lora(
                        fontSize: 14,
                        color: SettingsPalette.mutedText.withValues(alpha: 0.6),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: SettingsPalette.cardBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: SettingsPalette.coralRed,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.lora(
                      fontWeight: FontWeight.w600,
                      color: SettingsPalette.mutedText,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isReady
                      ? () => Navigator.pop(dialogContext, true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SettingsPalette.coralRed,
                    disabledBackgroundColor: SettingsPalette.coralRed
                        .withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Delete Account',
                    style: GoogleFonts.lora(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    confirmController.dispose();

    if (shouldDelete != true) return;

    setState(() => _isBusy = true);
    var deleted = false;
    try {
      deleted = await AccountLifecycleService.deleteAccountAndSignOut();
    } catch (e) {
      debugPrint('Delete account error: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }

    if (!mounted) return;
    if (!deleted) {
      _showSnackBar(
        'Could not delete your account right now. Please try again.',
        isError: true,
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ScreenFour()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Not set';
    final providerLabel = resolveAuthProviderLabel(user);
    final name = OnboardingData.instance.fullName.trim();
    final occupation = OnboardingData.instance.occupation.trim();
    final age = OnboardingData.instance.age;
    final originalScreenTime = OnboardingData.instance.dailyScreenTime;

    return Scaffold(
      backgroundColor: SettingsPalette.background,
      appBar: AppBar(
        backgroundColor: SettingsPalette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: SettingsPalette.primaryText,
          ),
        ),
        centerTitle: true,
        title: Text(
          'My Account',
          style: GoogleFonts.lora(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: SettingsPalette.primaryText,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card 1: Profile Details (matching screenshot layout)
                  SettingsGroupedCard(
                    children: [
                      SettingsTile(
                        leading: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SettingsPalette.softMint,
                            border: Border.all(
                              color: SettingsPalette.accentGreen.withValues(
                                alpha: 0.35,
                              ),
                              width: 1.4,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 19,
                            color: SettingsPalette.accentGreen,
                          ),
                        ),
                        title: 'Profile Photo',
                        trailingText: 'Default',
                        onTap: () => _showSnackBar(
                          'Using Oruv default person avatar',
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.person_rounded,
                        title: 'Your Name',
                        subtitle: name.isNotEmpty ? name : 'Add your name',
                        showChevron: true,
                        onTap: _editName,
                      ),
                      SettingsTile(
                        icon: Icons.work_rounded,
                        title: 'Occupation',
                        subtitle: occupation.isNotEmpty
                            ? occupation
                            : 'Add occupation',
                        showChevron: true,
                        onTap: _editOccupation,
                      ),
                      SettingsTile(
                        icon: Icons.cake_rounded,
                        title: 'My Age',
                        subtitle: age != null ? '$age' : 'Add your age',
                        showChevron: true,
                        onTap: _editAge,
                      ),
                      SettingsTile(
                        icon: Icons.hourglass_bottom_rounded,
                        title: 'Original Screen Time',
                        subtitle: originalScreenTime,
                        showChevron: true,
                        onTap: _editOriginalScreenTime,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Card 2: Email & Sign-In Method
                  SettingsGroupedCard(
                    children: [
                      SettingsTile(
                        icon: Icons.email_rounded,
                        title: 'Email',
                        subtitle: email,
                        showChevron: true,
                        onTap: () => _openEmailSheet(user, providerLabel),
                      ),
                      SettingsTile(
                        icon: providerLabel == 'Apple'
                            ? Icons.apple_rounded
                            : providerLabel == 'Google'
                            ? Icons.g_mobiledata_rounded
                            : Icons.verified_user_rounded,
                        title: 'Sign in with $providerLabel',
                        trailingText: 'Connected',
                        trailingColor: SettingsPalette.accentGreen,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Card 3: Sign out (matching screenshot)
                  SettingsGroupedCard(
                    children: [
                      SettingsTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign out',
                        onTap: _confirmSignOut,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      'Your focus schedules and preferences stay safely saved to your account.',
                      style: GoogleFonts.lora(
                        fontSize: 12.5,
                        color: SettingsPalette.mutedText,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Delete My Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isBusy ? null : _confirmDeleteAccount,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: SettingsPalette.softCoral,
                        foregroundColor: SettingsPalette.coralRed,
                        side: BorderSide(
                          color: SettingsPalette.coralRed.withValues(
                            alpha: 0.28,
                          ),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: Text(
                        'Delete My Account',
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
            if (_isBusy)
              Container(
                color: Colors.black.withValues(alpha: 0.12),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: SettingsPalette.accentGreen,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

