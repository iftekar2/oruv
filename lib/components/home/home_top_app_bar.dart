import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/signout.dart';

class HomeTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onProfileTap;

  const HomeTopAppBar({
    super.key,
    this.onProfileTap,
  });

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _cardBorder = Color(0xFFECE8E4);

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 18,
      title: Row(
        children: [
          Image.asset(
            'lib/components/images/logo.png',
            width: 44,
            height: 44,
          ),
          const SizedBox(width: 6),
          Text(
            'Oruv',
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onProfileTap ??
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignOut()),
                  );
                },
            icon: const Icon(
              Icons.person_outline_rounded,
              color: _primaryText,
              size: 22,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
                side: const BorderSide(
                  color: _cardBorder,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

