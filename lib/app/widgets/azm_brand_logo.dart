import 'package:flutter/material.dart';
import '../theme/azm_colors.dart';

/// شعار عزم الجبل والمسار الذهبي والنجمة مرسوم برمجيًا بجودة متجهة على كل الشاشات
class AzmBrandLogo extends StatelessWidget {
  final double size;
  final bool showStar;

  const AzmBrandLogo({
    super.key,
    this.size = 44,
    this.showStar = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AzmMountainPainter(showStar: showStar),
      ),
    );
  }
}

class _AzmMountainPainter extends CustomPainter {
  final bool showStar;
  _AzmMountainPainter({required this.showStar});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // الخلفية المتدرجة الدائرية/الناعمة
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AzmColors.primaryDeep, AzmColors.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.24),
    );
    canvas.drawRRect(rrect, bgPaint);

    // الجبل الرئيسي
    final mountainPath = Path()
      ..moveTo(w * 0.14, h * 0.80)
      ..lineTo(w * 0.50, h * 0.24)
      ..lineTo(w * 0.86, h * 0.80)
      ..close();

    final mountainPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    canvas.drawPath(mountainPath, mountainPaint);

    // ظل جانبي لإبراز البعد الثلاثي
    final shadowPath = Path()
      ..moveTo(w * 0.50, h * 0.24)
      ..lineTo(w * 0.86, h * 0.80)
      ..lineTo(w * 0.54, h * 0.80)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()..color = AzmColors.primarySoft.withValues(alpha: 0.75),
    );

    // المسار الذهبي الصاعد نحو القمة
    final pathGold = Path()
      ..moveTo(w * 0.34, h * 0.80)
      ..quadraticBezierTo(w * 0.60, h * 0.62, w * 0.44, h * 0.48)
      ..quadraticBezierTo(w * 0.38, h * 0.40, w * 0.50, h * 0.26);

    final goldPaint = Paint()
      ..color = AzmColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(pathGold, goldPaint);

    // نجمة القمة الذهبية
    if (showStar) {
      final starCenter = Offset(w * 0.50, h * 0.16);
      final starPaint = Paint()..color = AzmColors.gold;
      canvas.drawCircle(starCenter, w * 0.065, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AzmMountainPainter oldDelegate) =>
      oldDelegate.showStar != showStar;
}
