import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';

class FocusBoundaryPage extends StatefulWidget {
  final VoidCallback onFinish;
  final VoidCallback? onBack;

  const FocusBoundaryPage({
    super.key,
    required this.onFinish,
    this.onBack,
  });

  @override
  State<FocusBoundaryPage> createState() => _FocusBoundaryPageState();
}

class _FocusBoundaryPageState extends State<FocusBoundaryPage>
    with SingleTickerProviderStateMixin {
  late String _startTime;
  late String _endTime;
  late Set<String> _activeDays;
  late bool _strictLock;

  // Press-and-hold animation controller
  late AnimationController _holdController;

  final List<String> _dayKeys = ['M', 'T', 'W', 'T2', 'F', 'S', 'S2'];
  final List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _startTime = OnboardingData.instance.scheduleStart;
    _endTime = OnboardingData.instance.scheduleEnd;
    _activeDays = Set.from(OnboardingData.instance.activeDays);
    _strictLock = OnboardingData.instance.strictLock;

    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completeOnboarding();
      }
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  void _completeOnboarding() {
    OnboardingData.instance.scheduleStart = _startTime;
    OnboardingData.instance.scheduleEnd = _endTime;
    OnboardingData.instance.activeDays = _activeDays;
    OnboardingData.instance.strictLock = _strictLock;
    widget.onFinish();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? const TimeOfDay(hour: 9, minute: 0)
        : const TimeOfDay(hour: 17, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: widget.onBack,
                      color: const Color(0xFF1E1A1D),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  Text(
                    "Step 5 of 5",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8A8287),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "Your First Focus Boundary.",
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: const Color(0xFF1E1A1D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "A balanced daily container to protect your deepest work.",
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        color: const Color(0xFF6E686D),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Main Focus Container Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFECE7E2),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header badge
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Work Time Anchor",
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E1A1D),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F5F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Recommended for you",
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF077C6A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // TIME BLOCK Label
                          Text(
                            "TIME BLOCK",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: const Color(0xFF8A8287),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Start & Unlock time inputs
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _pickTime(isStart: true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFBF9F7),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFECE7E2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "STARTS",
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF8A8287),
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(
                                              Icons.access_time_rounded,
                                              size: 14,
                                              color: Color(0xFF8A8287),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _startTime,
                                          style: GoogleFonts.dmSerifDisplay(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1E1A1D),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFBF9F7),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFECE7E2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "UNLOCKS",
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF8A8287),
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(
                                              Icons.access_time_rounded,
                                              size: 14,
                                              color: Color(0xFF8A8287),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _endTime,
                                          style: GoogleFonts.dmSerifDisplay(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1E1A1D),
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

                          // ACTIVE SCHEDULE Label
                          Text(
                            "ACTIVE SCHEDULE",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: const Color(0xFF8A8287),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Day circles
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(_dayKeys.length, (idx) {
                              final key = _dayKeys[idx];
                              final label = _dayLabels[idx];
                              final isActive = _activeDays.contains(key);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isActive) {
                                      _activeDays.remove(key);
                                    } else {
                                      _activeDays.add(key);
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive
                                        ? const Color(0xFF1E1A1D)
                                        : const Color(0xFFF5F3EF),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    label,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFFB5AFB3),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFECE7E2), thickness: 0.8),
                          const SizedBox(height: 14),

                          // Apps count summary
                          Row(
                            children: [
                              const Icon(
                                Icons.apps_rounded,
                                size: 20,
                                color: Color(0xFF1E1A1D),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "25 Apps locked automatically",
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E1A1D),
                                ),
                              ),
                              const Spacer(),
                              // Small app badge icons
                              Row(
                                children: [
                                  _buildAppBadge("in", const Color(0xFF0077B5)),
                                  const SizedBox(width: 3),
                                  _buildAppBadge("tt", Colors.black),
                                  const SizedBox(width: 3),
                                  _buildAppBadge("yt", const Color(0xFFFF0000)),
                                  const SizedBox(width: 3),
                                  _buildAppBadge("+22", const Color(0xFF281F24)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Strict Lock Row
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF9F7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFECE7E2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEBE5DF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.shield_outlined,
                                    size: 20,
                                    color: Color(0xFF1E1A1D),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Strict Lock",
                                        style: GoogleFonts.dmSerifDisplay(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E1A1D),
                                        ),
                                      ),
                                      Text(
                                        "Safe countdown required to break",
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: const Color(0xFF8A8287),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _strictLock,
                                  onChanged: (val) {
                                    setState(() {
                                      _strictLock = val;
                                    });
                                  },
                                  activeColor: const Color(0xFF077C6A),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom White Card with Press-and-Hold
            Container(
              padding: const EdgeInsets.fromLTRB(28, 14, 28, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFDFCF8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0DCD6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Hold to Commit Button
                  GestureDetector(
                    onTapDown: (_) => _holdController.forward(),
                    onTapUp: (_) {
                      if (_holdController.status != AnimationStatus.completed) {
                        _holdController.reverse();
                      }
                    },
                    onTapCancel: () {
                      if (_holdController.status != AnimationStatus.completed) {
                        _holdController.reverse();
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _holdController,
                      builder: (context, child) {
                        return Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1A1D),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              // Fill progress indicator
                              FractionallySizedBox(
                                widthFactor: _holdController.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF077C6A),
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                              ),
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 19,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _holdController.value > 0
                                          ? "Holding..."
                                          : "Hold to Commit",
                                      style: GoogleFonts.outfit(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "Customize details later in settings",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF8A8287),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDED7CE),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDED7CE),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDED7CE),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 20,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF281F24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBadge(String text, Color bg) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

