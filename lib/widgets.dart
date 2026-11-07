import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app.dart';

/// Circular crop of the character's face (same crop as the HTML version).
class FaceWidget extends StatelessWidget {
  final ui.Image img;
  final double size;
  const FaceWidget(this.img, this.size, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: _FacePainter(img)));
}

class _FacePainter extends CustomPainter {
  final ui.Image im;
  _FacePainter(this.im);
  @override
  void paint(Canvas c, Size s) {
    c.clipPath(Path()..addOval(Offset.zero & s));
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF120D26));
    final sw = im.width * .5;
    c.drawImageRect(im, Rect.fromLTWH(im.width * .25, im.height * .03, sw, sw), Offset.zero & s,
        Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(covariant _FacePainter o) => o.im != im;
}

class StrokedText extends StatelessWidget {
  final String text;
  final double size;
  final Color fill, stroke;
  final double sw;
  const StrokedText(this.text, this.size, this.fill, this.stroke, this.sw, {super.key});
  @override
  Widget build(BuildContext context) => Stack(alignment: Alignment.center, children: [
        Text(text,
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w900,
                height: 1,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = sw
                  ..color = stroke)),
        Text(text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, height: 1, color: fill)),
      ]);
}

class PBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool outline;
  final double size, vpad, hpad;
  const PBtn(this.label, this.onTap,
      {super.key, this.color = kPur, this.outline = false, this.size = 16, this.vpad = 12, this.hpad = 26});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: vpad, horizontal: hpad),
          decoration: BoxDecoration(
              color: outline ? Colors.transparent : color,
              border: Border.all(color: kPur),
              borderRadius: BorderRadius.circular(10)),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size)),
        ),
      );
}

class PageTop extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback onBack;
  const PageTop(this.title, this.onBack, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: kBox, border: Border.all(color: kPur, width: 2), borderRadius: BorderRadius.circular(10)),
              child: const Text('↩', style: TextStyle(color: Colors.white, fontSize: 22)),
            ),
          ),
          Expanded(
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD8B4FE),
                      shadows: [Shadow(color: Color(0xFFA855F7), blurRadius: 12)]))),
          trailing ?? const SizedBox(width: 44),
        ]),
      );
}

class Pg extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  const Pg({super.key, required this.child, this.gradient});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            gradient: gradient ??
                const RadialGradient(center: Alignment(0, -1), radius: 1.2, colors: [Color(0xFF2A1A5C), kBg], stops: [0, .7])),
        child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(14, 12, 14, 30), child: child)),
      );
}

BoxDecoration boxDeco({double r = 16}) =>
    BoxDecoration(color: kBox, border: Border.all(color: kLn), borderRadius: BorderRadius.circular(r));
