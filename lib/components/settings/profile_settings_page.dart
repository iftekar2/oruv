import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';
import 'package:oruv/components/onboarding/onboarding_service.dart';
import 'package:oruv/components/settings/my_account_page.dart';
import 'package:oruv/components/settings/settings_sheets.dart';
import 'package:oruv/components/welcomePages/screenFour.dart';
import 'package:oruv/services/google_auth_service.dart';
import 'package:oruv/services/preferences_service.dart';
import 'package:oruv/services/screen_time_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  bool _isSigningOut = false;
  bool _notificationsEnabled = false;
  int _mindfulBreakDefaultMinutes = 5;
  bool _screenTimeAuthorized = false;

  static const List<OptionPickerItem<String>> _priorityOptions = [
    OptionPickerItem(
      value: 'Deep Work & Career Focus',
      title: 'Deep Work & Career Focus',
      subtitle: 'Protect unbroken hours for high-value building',
      icon: Icons.work_outline_rounded,
    ),
    OptionPickerItem(
      value: 'Reclaim Evening & Sleep Peace',
      title: 'Reclaim Evening & Sleep Peace',
      subtitle: 'Stop late-night doomscrolling and blue light',
      icon: Icons.nightlight_outlined,
    ),
    OptionPickerItem(
      value: 'Presence with Family & Friends',
      title: 'Presence with Family & Friends',
      subtitle: 'Be genuinely present with loved ones',
      icon: Icons.favorite_border_rounded,
    ),
    OptionPickerItem(
      value: 'Mental Clarity & Calm',
      title: 'Mental Clarity & Calm',
      subtitle: 'Reduce notification noise and fragmented focus',
      icon: Icons.spa_outlined,
    ),
  ];

  static const List<OptionPickerItem<int>> _breakDurationOptions = [
    OptionPickerItem(
      value: 5,
      title: '5 minutes',
      subtitle: 'Quick breath and reset before returning',
      icon: Icons.timer_outlined,
    ),
    OptionPickerItem(
      value: 10,
      title: '10 minutes',
      subtitle: 'Short walk, stretch, or hydration pause',
      icon: Icons.self_improvement_rounded,
    ),
    OptionPickerItem(
      value: 15,
      title: '15 minutes',
      subtitle: 'Full mental recharge between focus blocks',
      icon: Icons.coffee_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettingsState();
  }

  Future<void> _loadSettingsState() async {
    await OnboardingService.loadOnboardingData();
    final notifications = await PreferencesService.getNotificationsEnabled();
    final breakMins = await PreferencesService.getMindfulBreakDefaultMinutes();
    final snapshot = await ScreenTimeService.fetchDailyScreenTime();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notifications;
      _mindfulBreakDefaultMinutes = breakMins;
      _screenTimeAuthorized =
          snapshot.isAuthorized || OnboardingData.instance.screenTimeAuthorized;
    });
  }

  String _resolveDisplayName(User? user) {
    final fullName = OnboardingData.instance.fullName.trim();
    if (fullName.isNotEmpty) return fullName;

    final metaName =
        (user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'])
            ?.toString()
            .trim();
    if (metaName != null && metaName.isNotEmpty) return metaName;

    final email = user?.email ?? '';
    if (email.contains('@')) {
      final handle = email.split('@').first;
      if (handle.isNotEmpty) {
        return handle[0].toUpperCase() + handle.substring(1);
      }
    }
    return 'Oruv Member';
  }

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

  Future<void> _openMyAccountPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyAccountPage()),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleNotifications() async {
    final next = !_notificationsEnabled;
    setState(() => _notificationsEnabled = next);
    await PreferencesService.setNotificationsEnabled(next);
    _showSnackBar(
      next ? 'Focus reminders turned on' : 'Focus reminders turned off',
    );
  }

  Future<void> _pickFocusPriority() async {
    final selected = await showSettingsOptionSheet<String>(
      context: context,
      title: 'Focus Priority',
      subtitle: 'What matters most to your daily focus',
      headerIcon: Icons.track_changes_rounded,
      options: _priorityOptions,
      currentValue: OnboardingData.instance.focusPriority,
    );
    if (selected == null || selected == OnboardingData.instance.focusPriority) {
      return;
    }
    setState(() => OnboardingData.instance.focusPriority = selected);
    await OnboardingService.saveOnboardingData();
    _showSnackBar('Focus priority updated');
  }

  Future<void> _pickScreenTimeGoal() async {
    final selected = await showSettingsOptionSheet<String>(
      context: context,
      title: 'Daily Screen Time Goal',
      subtitle: 'Used to track progress in your Insights tab',
      headerIcon: Icons.timelapse_rounded,
      options: kScreenTimeGoalOptions,
      currentValue: OnboardingData.instance.dailyScreenTime,
    );
    if (selected == null ||
        selected == OnboardingData.instance.dailyScreenTime) {
      return;
    }
    setState(() => OnboardingData.instance.dailyScreenTime = selected);
    await OnboardingService.saveOnboardingData();
    _showSnackBar('Daily goal updated to $selected');
  }

  Future<void> _pickMindfulBreakDefault() async {
    final selected = await showSettingsOptionSheet<int>(
      context: context,
      title: 'Mindful Break Default',
      subtitle: 'Pre-selected duration when starting a break',
      headerIcon: Icons.self_improvement_rounded,
      options: _breakDurationOptions,
      currentValue: _mindfulBreakDefaultMinutes,
    );
    if (selected == null || selected == _mindfulBreakDefaultMinutes) return;
    setState(() => _mindfulBreakDefaultMinutes = selected);
    await PreferencesService.setMindfulBreakDefaultMinutes(selected);
    _showSnackBar('Default mindful break set to $selected min');
  }

  Future<void> _toggleStrictMode() async {
    final next = !OnboardingData.instance.strictLock;
    setState(() => OnboardingData.instance.strictLock = next);
    await OnboardingService.saveOnboardingData();
    _showSnackBar(
      next ? 'Strict enforcement enabled' : 'Strict enforcement turned off',
    );
  }

  Future<void> _handleScreenTimeAccess() async {
    if (_screenTimeAuthorized) {
      _showSnackBar('Screen Time access is connected');
      return;
    }
    final granted = await ScreenTimeService.requestAuthorization();
    if (!mounted) return;
    setState(() {
      _screenTimeAuthorized = granted;
      OnboardingData.instance.screenTimeAuthorized = granted;
    });
    if (granted) {
      await OnboardingService.saveOnboardingData();
      _showSnackBar('Screen Time access connected');
    } else {
      _showSnackBar(
        'Enable Screen Time access in system settings to continue',
        isError: true,
      );
    }
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SettingsPalette.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Log out of Oruv?',
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
              backgroundColor: SettingsPalette.coralRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Log Out',
              style: GoogleFonts.lora(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await _performSignOut();
    }
  }

  Future<void> _performSignOut() async {
    setState(() => _isSigningOut = true);
    try {
      await GoogleAuthService.signOut();
      await Supabase.instance.client.auth.signOut();
      await PreferencesService.setCompletedOnboarding(true);
      OnboardingData.instance.reset();
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ScreenFour()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = _resolveDisplayName(user);
    final email = user?.email ?? '';

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
          'Profile & Settings',
          style: GoogleFonts.lora(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: SettingsPalette.primaryText,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Centered Default Person Avatar + User's Name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SettingsPalette.avatarBg,
                        border: Border.all(
                          color: SettingsPalette.cardBorder,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 46,
                        color: SettingsPalette.primaryText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: SettingsPalette.primaryText,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lora(
                          fontSize: 13.5,
                          color: SettingsPalette.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Account Section
              const _SectionLabel(title: 'Account'),
              const SizedBox(height: 10),
              SettingsGroupedCard(
                children: [
                  SettingsTile(
                    icon: Icons.person_rounded,
                    title: 'My Account',
                    onTap: _openMyAccountPage,
                    showChevron: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Personalize Section
              const _SectionLabel(title: 'Personalize'),
              const SizedBox(height: 10),
              SettingsGroupedCard(
                children: [
                  SettingsTile(
                    icon: Icons.notifications_rounded,
                    title: 'Focus Reminders',
                    trailingText: _notificationsEnabled ? 'On' : 'Off',
                    trailingColor: _notificationsEnabled
                        ? SettingsPalette.accentGreen
                        : SettingsPalette.mutedText,
                    onTap: _toggleNotifications,
                  ),
                  SettingsTile(
                    icon: Icons.track_changes_rounded,
                    title: 'Focus Priority',
                    subtitle: OnboardingData.instance.focusPriority,
                    onTap: _pickFocusPriority,
                    showChevron: true,
                  ),
                  SettingsTile(
                    icon: Icons.timelapse_rounded,
                    title: 'Daily Screen Time Goal',
                    subtitle: 'Baseline target used in your Insights',
                    trailingText: OnboardingData.instance.dailyScreenTime,
                    onTap: _pickScreenTimeGoal,
                    showChevron: true,
                  ),
                  SettingsTile(
                    icon: Icons.self_improvement_rounded,
                    title: 'Mindful Break Default',
                    subtitle: 'Default pause duration before resuming focus',
                    trailingText: '$_mindfulBreakDefaultMinutes min',
                    onTap: _pickMindfulBreakDefault,
                    showChevron: true,
                  ),
                  SettingsTile(
                    icon: Icons.shield_rounded,
                    title: 'Strict Enforcement',
                    subtitle: 'Require mindful countdown before unblocking',
                    trailingText: OnboardingData.instance.strictLock
                        ? 'On'
                        : 'Off',
                    trailingColor: OnboardingData.instance.strictLock
                        ? SettingsPalette.accentGreen
                        : SettingsPalette.mutedText,
                    onTap: _toggleStrictMode,
                  ),
                  SettingsTile(
                    icon: Icons.phonelink_lock_rounded,
                    title: 'Screen Time Access',
                    subtitle: 'System permission for shielding & usage insights',
                    trailingText: _screenTimeAuthorized ? 'Connected' : 'Off',
                    trailingColor: _screenTimeAuthorized
                        ? SettingsPalette.accentGreen
                        : SettingsPalette.mutedText,
                    onTap: _handleScreenTimeAccess,
                    showChevron: !_screenTimeAuthorized,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Log Out Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isSigningOut ? null : _confirmSignOut,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: SettingsPalette.softCoral,
                    foregroundColor: SettingsPalette.coralRed,
                    side: BorderSide(
                      color: SettingsPalette.coralRed.withValues(alpha: 0.28),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: _isSigningOut
                      ? const SizedBox.shrink()
                      : const Icon(Icons.logout_rounded, size: 20),
                  label: _isSigningOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SettingsPalette.coralRed,
                          ),
                        )
                      : Text(
                          'Log Out',
                          style: GoogleFonts.lora(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Oruv • Version 1.0.0',
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    color: SettingsPalette.mutedText.withValues(alpha: 0.75),
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

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.lora(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: SettingsPalette.primaryText,
        ),
      ),
    );
  }
}
