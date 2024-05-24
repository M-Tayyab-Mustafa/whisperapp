import 'package:flutter/material.dart';

import 'package:whisperapp/views/auth/welcome/slide_model.dart';


class PageViewSlide extends StatelessWidget {
  const PageViewSlide({super.key,
    required this.slide,
  });

  final Slide slide;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E7895);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Move the image up
        children: [
          const SizedBox(height: 60.0), // Reduced space
          Image.asset(
            slide.svgUrl,
            height: 200,
            color: primaryColor,
          ),
          const SizedBox(height: 20.0),
          Text(
            slide.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10.0),
          Text(
            slide.subTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.black,
              letterSpacing: 1,
            ),
          )
        ],
      ),
    );
  }
}