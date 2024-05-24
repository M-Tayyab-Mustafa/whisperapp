import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class RoundButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool loading;
  final Color color; // Button color
  final Color titleColor; // Add this line for title color
  final FontWeight fontWeight;

  const RoundButton({
    Key? key,
    required this.title,
    required this.onTap,
    this.loading = false,
    this.color = const Color(0xFF1E7895), // Default button color
    this.titleColor = Colors.white, // Default title color
    required this.fontWeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color, // Use the passed color for the button
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: loading
              ? LoadingAnimationWidget.fourRotatingDots(
            color: titleColor, // Use title color for the loader as well
            size: 40,
          )
              : Text(
            title,
            style: TextStyle(
              color: titleColor, // Use the passed color for the title
              fontWeight: fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}
