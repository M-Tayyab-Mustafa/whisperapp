
class Slide {
  final String svgUrl;
  final String title;
  final String subTitle;

  Slide({required this.svgUrl, required this.title, required this.subTitle})
      : assert(
  svgUrl != null && title != null && subTitle != null,
  );
}
