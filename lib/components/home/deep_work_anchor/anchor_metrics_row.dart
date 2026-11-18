import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AnchorMetricsRow extends StatelessWidget {
  final String? sessionRemaining;
  final bool isAuthorized;
  final bool isSavingTime;
  final String? projectedTimeText;
  final String? projectedLabel;
  final String? protectedToday;
  final String focusedDuration;
  final int mostBlockedAppCount;
  final String mostBlockedAppName;
  final bool hasMostBlockedNativeToken;

  static const Color _accentGreen = Color(0xFF1D6F58);
  static const Color _coralRed = Color(0xFFD94841);
  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);

  const AnchorMetricsRow({
    super.key,
    required this.sessionRemaining,
    required this.isAuthorized,
    required this.isSavingTime,
    required this.projectedTimeText,
    required this.projectedLabel,
    required this.protectedToday,
    required this.focusedDuration,
    required this.mostBlockedAppCount,
    required this.mostBlockedAppName,
    required this.hasMostBlockedNativeToken,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column 1: Session Remaining
        Expanded(
          child: AnchorMetricColumn(
            value: sessionRemaining ?? '0m',
            label: 'Session Remaining',
            valueColor: _primaryText,
          ),
        ),

        Container(width: 1, height: 45, color: const Color(0xFFEEEAE6)),

        // Column 2: Projected / On Track to Save
        Expanded(
          child: (Platform.isIOS && isAuthorized)
              ? const SizedBox(
                  height: 52,
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: UiKitView(
                        viewType: 'oruv/anchor_time_saved',
                        creationParamsCodec: StandardMessageCodec(),
                        hitTestBehavior:
                            PlatformViewHitTestBehavior.transparent,
                      ),
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 32,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              isSavingTime
                                  ? Icons.arrow_drop_down_sharp
                                  : Icons.arrow_drop_up_sharp,
                              size: 25,
                              color: isSavingTime ? _accentGreen : _coralRed,
                            ),
                            Flexible(
                              child: Text(
                                projectedTimeText ??
                                    (protectedToday ?? focusedDuration),
                                style: GoogleFonts.lora(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isSavingTime ? _accentGreen : _coralRed,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      projectedLabel ??
                          (isSavingTime ? 'On Track to Save' : 'Over Yest.'),
                      style: GoogleFonts.lora(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _mutedText,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
        ),

        Container(width: 1, height: 45, color: const Color(0xFFEEEAE6)),

        // Column 3: Urges / Most Blocked App
        Expanded(
          child: AnchorMetricColumn(
            value: mostBlockedAppCount > 0
                ? '${mostBlockedAppCount}X'
                : '0',
            label: 'Urges Blocked',
            valueColor: _primaryText,
            customLabelWidget: mostBlockedAppCount > 0
                ? (mostBlockedAppName.isNotEmpty
                      ? Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: mostBlockedAppName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryText,
                                  height: 1.2,
                                ),
                              ),
                              TextSpan(
                                text: ' Blocked',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryText,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : (hasMostBlockedNativeToken && Platform.isIOS
                            ? const Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Apps',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _primaryText,
                                        height: 1.2,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' Blocked',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryText,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null))
                : null,
          ),
        ),
      ],
    );
  }
}

class AnchorMetricColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final Widget? prefixIcon;
  final Widget? customLabelWidget;

  static const Color _mutedText = Color(0xFF6E6A6E);

  const AnchorMetricColumn({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
    this.prefixIcon,
    this.customLabelWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 32,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (prefixIcon != null) ...[
                  prefixIcon!,
                  const SizedBox(width: 2),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (customLabelWidget != null)
          customLabelWidget!
        else
          Text(
            label,
            style: GoogleFonts.lora(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _mutedText,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
