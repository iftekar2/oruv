import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';

class AppShieldPage extends StatefulWidget {
  final VoidCallback? onChanged;

  const AppShieldPage({
    super.key,
    this.onChanged,
  });

  @override
  State<AppShieldPage> createState() => AppShieldPageState();
}

class AppShieldPageState extends State<AppShieldPage> {
  static const MethodChannel _screenTimeChannel =
      MethodChannel('oruv/screen_time');

  bool _isRequestingPermission = false;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    _screenTimeChannel.setMethodCallHandler(_handleNativeCallback);
    _checkExistingStatus();
  }

  Future<dynamic> _handleNativeCallback(MethodCall call) async {
    if (call.method == 'onSelectionChanged') {
      final args = call.arguments as Map<dynamic, dynamic>?;
      if (args != null && mounted) {
        setState(() {
          OnboardingData.instance.nativeSelectedAppsCount =
              (args['appsCount'] as int?) ?? 0;
          OnboardingData.instance.nativeSelectedCategoriesCount =
              (args['categoriesCount'] as int?) ?? 0;
          OnboardingData.instance.nativeSelectedDomainsCount =
              (args['domainsCount'] as int?) ?? 0;
        });
        widget.onChanged?.call();
      }
    }
  }

  Future<void> _checkExistingStatus() async {
    if (!Platform.isIOS) return;
    try {
      final res = await _screenTimeChannel
          .invokeMapMethod<String, dynamic>('checkAuthorizationStatus');
      final approved = res?['authorized'] == true;
      if (approved && mounted) {
        setState(() {
          OnboardingData.instance.screenTimeAuthorized = true;
        });
        widget.onChanged?.call();
      }
    } catch (_) {}
  }

  Future<void> requestScreenTimePermission() async {
    if (_isRequestingPermission) return;
    setState(() {
      _isRequestingPermission = true;
      _permissionError = null;
    });

    try {
      final res = await _screenTimeChannel
          .invokeMapMethod<String, dynamic>('requestAuthorization');
      final approved = res?['authorized'] == true;
      final errorMsg = res?['error'] as String?;

      if (!mounted) return;
      if (approved) {
        setState(() {
          _isRequestingPermission = false;
          OnboardingData.instance.screenTimeAuthorized = true;
        });
        widget.onChanged?.call();
      } else {
        setState(() {
          _isRequestingPermission = false;
          _permissionError = errorMsg ??
              "Screen Time access was not granted. Please tap Confirm on the system prompt.";
        });
      }
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _isRequestingPermission = false;
        _permissionError =
            "Native Screen Time bridge requires a full rebuild (stop the app and run 'flutter run' again).";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRequestingPermission = false;
        _permissionError = e.toString();
      });
    }
  }

  void _showLearnMoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_person_rounded,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "100% On-Device Privacy",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  "Oruv uses Apple's official Screen Time API (FamilyControls). Apple's privacy architecture ensures that your personal browsing history and app usage data never leave your iPhone.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      "Got It",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
  }

  @override
  Widget build(BuildContext context) {
    final authorized = OnboardingData.instance.screenTimeAuthorized;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: authorized
            ? _buildNativeAppPickerView()
            : _buildPermissionPromptView(),
      ),
    );
  }

  Widget _buildPermissionPromptView() {
    return SingleChildScrollView(
      key: const ValueKey('permission_prompt_view'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            "Let's connect Oruv to Screen Time\nsettings. Securely.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 36),

          // Glowing iOS Screen Time Alert Preview Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: const Color(0xFF8CE9C6).withValues(alpha: 0.85),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.22),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF222425),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "“Oruv” Would Like to Access\nScreen Time",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Providing “Oruv” access to Screen Time may allow it to see your activity data, restrict content, and limit the usage of Apps & Websites.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: requestScreenTimePermission,
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF565A59),
                              borderRadius: BorderRadius.circular(23),
                            ),
                            alignment: Alignment.center,
                            child: _isRequestingPermission
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    "Confirm",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D303F),
                            borderRadius: BorderRadius.circular(23),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Don’t Allow",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5E7A93),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Curved Neon Arrow pointing up to "Confirm"
          Align(
            alignment: const Alignment(-0.42, 0),
            child: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: SizedBox(
                width: 60,
                height: 76,
                child: CustomPaint(
                  painter: _CurvedArrowPainter(),
                ),
              ),
            ),
          ),

          if (_permissionError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                _permissionError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Colors.red.shade200,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          Text(
            "Your information is protected by Apple and will\nstay 100% on your phone.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showLearnMoreSheet,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                "Learn More",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Embeds Apple's actual native SwiftUI `FamilyActivityPicker` via UiKitView,
  /// which lists the real apps & categories installed on the user's iPhone.
  Widget _buildNativeAppPickerView() {
    return Padding(
      key: const ValueKey('native_app_picker_view'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Use ",
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Icon(
                Icons.search_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              Text(
                " Search or tap ",
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              Text(
                " to select apps/websites",
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Platform.isIOS
                  ? const UiKitView(
                      viewType: 'oruv/family_activity_picker',
                      creationParamsCodec: StandardMessageCodec(),
                    )
                  : Center(
                      child: Text(
                        "Apple Screen Time picker is only available on iOS devices.",
                        style: GoogleFonts.inter(color: Colors.white70),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _CurvedArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8CE9C6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.92);
    path.quadraticBezierTo(
      size.width * 0.55,
      size.height * 0.65,
      size.width * 0.52,
      size.height * 0.08,
    );
    canvas.drawPath(path, paint);

    final headPath = Path();
    headPath.moveTo(size.width * 0.36, size.height * 0.22);
    headPath.lineTo(size.width * 0.52, size.height * 0.06);
    headPath.lineTo(size.width * 0.68, size.height * 0.22);
    canvas.drawPath(headPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
