import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTile extends StatelessWidget {
  const CustomTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8.0),
            SvgPicture.asset(
              icon,
              color: Colors.black,
              height: 22,
            ),
            const SizedBox(width: 8.0),
            Text(
              title,
              style: GoogleFonts.lato(fontSize: 14),
            ),
            const Expanded(child: Row()),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }
}
