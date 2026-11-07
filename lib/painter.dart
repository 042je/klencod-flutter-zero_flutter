import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'assets.dart';
import 'data.dart';
import 'game.dart';

const _brightness3 = ColorFilter.matrix(<double>[
  3, 0, 0, 0, 0, //
  0, 3, 0, 0, 0, //
  0, 0, 3, 0, 0, //
  0, 0, 0, 1, 0,
]);

class GamePainter extends CustomPainter {
  final Game g;
  final Assets A;
  GamePainter(this.g, this.A, Listenable repaint) : super(repaint: repaint);

  late Canvas c;
  final Paint _p = Paint()..filterQuality = FilterQuality.medium;
  final Paint _fill = Paint();

  void _img(ui.Image im, double sx, double sy, double sw, double sh, double dx, double dy, double dw, double dh,
      [Paint? paint]) {
    c.drawImageRect(im, Rect.fromLTWH(sx, sy, sw, sh), Rect.fromLTWH(dx, dy, dw, dh), paint ?? _p);
  }

  void _full(ui.Image im, double dx, double dy, double dw, double dh, [Paint? paint]) =>
      _img(im, 0, 0, im.width.toDouble(), im.height.toDouble(), dx, dy, dw, dh, paint);

  void _shadow(double x, double y, double rx, double ry, double a) {
    _fill
      ..shader = null
      ..maskFilter = null
      ..color = Color.fromRGBO(0, 0, 0, a);
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2), _fill);
  }

  void _glow(double x, double y, double r, Color core, Color glow, double blur) {
    c.drawCircle(
        Offset(x, y), r, Paint()..color = glow..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2));
    c.drawCircle(Offset(x, y), r, Paint()..color = core);
  }

  void _text(String s, double x, double y, double size, Color color, {Color? stroke, double sw = 3}) {
    TextPainter mk(Paint? fg, Color? col) => TextPainter(
          text: TextSpan(
              text: s,
              style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.bold,
                  color: fg == null ? col : null,
                  foreground: fg)),
          textDirection: TextDirection.ltr,
        )..layout();
    final tp = mk(null, color);
    final base = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final off = Offset(x - tp.width / 2, y - base);
    if (stroke != null) {
      mk(Paint()..style = PaintingStyle.stroke..strokeWidth = sw..color = stroke..strokeJoin = StrokeJoin.round, null)
          .paint(c, off);
    }
    tp.paint(c, off);
  }

  @override
  void paint(Canvas canvas, Size size) {
    c = canvas;
    final W = size.width, H = size.height;
    final Z = max(1.2, min(2.0, min(W, H) / 310));
    c.drawRect(Rect.fromLTWH(0, 0, W, H), Paint()..color = const Color(0xFF0D0D1A));
    c.save();
    c.clipRect(Rect.fromLTWH(0, 0, W, H));
    c.scale(Z, Z);
    final VW = W / Z, VH = H / Z;
    final P = g.P;
    final tx = (P.x - VW / 2).clamp(0.0, max(0.0, WW - VW)).toDouble();
    final ty = (P.y - 40 - VH / 2).clamp(0.0, max(0.0, WH - VH)).toDouble();
    if (g.camSnap) {
      g.camX = tx;
      g.camY = ty;
      g.camSnap = false;
    } else {
      g.camX += (tx - g.camX) * .18;
      g.camY += (ty - g.camY) * .18;
    }
    c.save();
    c.translate(-g.camX + rnd(-1, 1) * g.shake, -g.camY + rnd(-1, 1) * g.shake);
    _full(A.map, 0, 0, WW, WH);

    // mana orbs
    for (final o in g.O) {
      final y = o.y - 20 + sin(g.t * 3 + o.ph) * 4;
      _glow(o.x, y, 7, const Color(0xFFE9D5FF), const Color(0xFFA78BFA), 14);
    }
    // healing orbs (ground)
    for (final h in g.HO) {
      final y = h.y - 18 + sin(g.t * 3 + h.ph) * 4, r = 9 + sin(g.t * 5 + h.ph) * 1.2;
      _shadow(h.x, h.y, 8, 3, .25);
      _glow(h.x, y, r * .8, const Color(0xFF86EFAC), const Color(0xFF4ADE80), 18);
      final w = Paint()..color = Colors.white;
      c.drawRect(Rect.fromLTWH(h.x - 1.5, y - 5, 3, 10), w);
      c.drawRect(Rect.fromLTWH(h.x - 5, y - 1.5, 10, 3), w);
    }

    final items = <MapEntry<double, void Function()>>[
      for (final e in g.E) MapEntry(e.y, () => _drawE(e)),
      MapEntry(P.y, _drawP),
    ];
    items.sort((a, b) => a.key.compareTo(b.key));
    for (final i in items) i.value();

    for (final p in g.PR) {
      _glow(p.x, p.y, 6, const Color(0xFFE9D5FF), const Color(0xFFA855F7), 14);
    }
    for (final f in g.fx) _drawFx(f);
    c.restore();
    c.drawRect(Rect.fromLTWH(0, 0, VW, VH), Paint()..color = g.S.tint);
    c.restore();
  }

  void _drawFx(Fx f) {
    final P = g.P;
    if (f.k == 'p') {
      c.drawRect(Rect.fromLTWH(f.x, f.y, 3, 3), Paint()..color = const Color(0xFFC4B5FD));
    } else if (f.k == 'd') {
      c.drawCircle(Offset(f.x, f.y), 3 + (.35 - f.t) * 8, Paint()..color = Color.fromRGBO(200, 190, 230, f.t.clamp(0.0, 1.0).toDouble()));
    } else if (f.k == 'dm') {
      final y = f.y - (1 - f.t / .7) * 24;
      _text(f.v, f.x, y, f.cr ? 18 : 14, f.g ? const Color(0xFF86EFAC) : f.cr ? const Color(0xFFFDE047) : Colors.white,
          stroke: Colors.black);
    } else if (f.k == 'heal') {
      c.drawCircle(
          Offset(P.x, P.y - 40),
          16 + (1 - f.t / .8) * 34,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Color.fromRGBO(134, 239, 172, f.t.clamp(0.0, 1.0).toDouble()));
    } else if (f.k == 'hit') {
      c.drawCircle(Offset(P.x, P.y - 40), 24, Paint()..color = const Color.fromRGBO(224, 58, 78, .45));
    } else if (f.k == 'slash') {
      final pr = 1 - f.t / f.m, s0 = f.a - 1.4, s1 = s0 + 2.8 * min(1.0, pr * 1.7);
      final alpha = (1 - pr * pr).clamp(0.0, 1.0);
      final rect = Rect.fromCircle(center: Offset(f.x, f.y), radius: 50);
      c.drawArc(
          rect,
          s0,
          s1 - s0,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 8 * (1 - pr * .5)
            ..color = f.c.withOpacity(alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      c.drawArc(
          rect,
          s0,
          s1 - s0,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 8 * (1 - pr * .5)
            ..color = f.c.withOpacity(alpha));
      final ws = max(s0, s1 - 1.3);
      c.drawArc(
          rect,
          ws,
          s1 - ws,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 2.5
            ..color = Colors.white.withOpacity(alpha));
    }
  }

  // ---------- sword
  void _drawSword(double hx, double hy) {
    final si = A.swords[g.G.s], P = g.P, dv = DIRS[P.dir]!;
    const L = 56.0;
    final sw = si.width * L / si.height, ax = atan2(L, sw * .88);
    double a;
    if (P.atkT > 0) {
      final ap = 1 - P.atkT / ATK, ez = ap < .25 ? ap / .25 * .1 : .1 + (ap - .25) / .75 * .9;
      a = atan2(dv[1], dv[0]) + (ez - .5) * 2.8;
    } else {
      final base = {'right': 1.0, 'left': pi - 1.0, 'down': 1.35, 'up': 1.8}[P.dir]!;
      a = base + (P.moving ? sin(P.walk) * .12 : sin(g.t * 2) * .03);
    }
    c.save();
    c.translate(hx, hy);
    c.rotate(a - ax);
    _full(si, -sw * .07, -L * .12, sw, L);
    c.restore();
  }

  // ---------- player
  void _drawP() {
    final P = g.P, cd = CH[g.G.c], ci = A.chars[cd.k]!, dv = DIRS[P.dir]!;
    ui.Image im = ci.down;
    var fl = false;
    if (P.dir == 'up') {
      im = ci.up;
    } else if (P.dir != 'down') {
      im = ci.side;
      fl = P.dir == 'right' ? !cd.sf : cd.sf;
    }
    final mv = P.moving ? 1.0 : 0.0, sd = P.dir == 'left' || P.dir == 'right';
    final WL = P.dir == 'down' ? ci.walk : (sd ? ci.sw : ci.bk);
    var wk = false;
    if (WL != null && (P.moving || P.dir == 'down')) {
      final idx = P.moving ? (P.walk / (pi * .75)).floor() % WL.length : 0;
      im = WL[idx];
      wk = true;
    }
    final h = wk ? 104 * (sd ? ci.whs : (P.dir == 'up' ? ci.whb : ci.wh)) : 104.0;
    final w = im.width * h / im.height, s = sin(P.walk) * mv, bob = mv * s.abs() * 3.5, hd = g.hand();
    var ox = 0.0, oy = 0.0, rot = mv * (P.vx / P.sp * .07 + s * .025);
    if (P.atkT > 0) {
      final e = sin((1 - P.atkT / ATK) * pi);
      ox = dv[0] * e * 10;
      oy = dv[1] * e * 7;
      rot += dv[0] * e * .12;
    }
    final idle = P.moving ? 0.0 : sin(g.t * 2.2) * .6;
    _shadow(P.x, P.y, 13 - bob * .5, 4, .3);
    final hx = P.x + ox + hd[0], hy = P.y + oy - bob + hd[1];
    if (P.dir == 'up') _drawSword(hx, hy);
    final blink = P.inv > 0 && (g.t * 20).floor() % 2 == 1;
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromRGBO(255, 255, 255, blink ? .4 : 1);
    final iw = im.width.toDouble(), ih = im.height.toDouble(), cut = .64, ct = ih * cut, th = h * cut, lh = h - th;
    final top = -lh - bob, Lf = max(0.0, s) * 5, Rf = max(0.0, -s) * 5, sh = sd ? s * 7 : 0.0, sp = sd ? 0.0 : s.abs() * 1.5;
    c.save();
    c.translate(P.x + ox, P.y + oy);
    c.rotate(rot);
    if (fl) c.scale(-1, 1);
    if (wk) {
      _full(im, -w / 2, -h - bob * .5, w, h, paint);
    } else {
      _img(im, 0, 0, iw, ct, -w / 2, -h - bob - idle * .5, w, th + .6, paint);
      _img(im, 0, ct, iw / 2, ih - ct, -w / 2 + sh - sp, top, w / 2, lh + bob - Lf, paint);
      _img(im, iw / 2, ct, iw / 2, ih - ct, -sh + sp, top, w / 2, lh + bob - Rf, paint);
    }
    c.restore();
    if (P.dir != 'up') _drawSword(hx, hy);
  }

  // ---------- ghost (drawn in code)
  void _ghost(double h, double w) {
    final t = g.t;
    c.drawRect(
        Rect.fromLTWH(-h, -h * 1.5, h * 2, h * 2),
        Paint()
          ..shader = ui.Gradient.radial(Offset(0, -h * .5), h * .9,
              [const Color.fromRGBO(168, 85, 247, .35), const Color.fromRGBO(168, 85, 247, 0)], [4 / (h * .9), 1]));
    final path = Path()..moveTo(-w / 2, 0);
    path.cubicTo(-w / 2, -h * 1.35, w / 2, -h * 1.35, w / 2, 0);
    for (var i = 1; i <= 4; i++) {
      final xe = w / 2 - i * w / 4;
      path.quadraticBezierTo(xe + w / 8, (i % 2 == 1 ? 12 : -3) + sin(t * 6 + i) * 3, xe, sin(t * 6 + i * 2) * 3);
    }
    path.close();
    c.saveLayer(null, Paint()..color = const Color.fromRGBO(255, 255, 255, .9));
    c.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset(0, -h), const Offset(0, 6), [const Color(0xFF7C5BD0), const Color(0xFF2B1760)]));
    c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF120A2A));
    c.drawOval(Rect.fromCenter(center: Offset(-w * .2, -h * .78), width: w * .2, height: h * .24),
        Paint()..color = const Color.fromRGBO(255, 255, 255, .12));
    for (final s in [-1.0, 1.0]) {
      c.save();
      c.translate(s * w * .2, -h * .55);
      c.rotate(s * .25);
      final r = Rect.fromCenter(center: Offset.zero, width: w * .2, height: h * .2);
      c.drawOval(r, Paint()..color = const Color(0xFFC084FC)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      c.drawOval(r, Paint()..color = const Color(0xFFEDE9FE));
      c.restore();
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF120A2A);
    c.drawLine(Offset(-w * .32, -h * .7), Offset(-w * .08, -h * .6), line);
    c.drawLine(Offset(w * .32, -h * .7), Offset(w * .08, -h * .6), line);
    c.drawOval(Rect.fromCenter(center: Offset(0, -h * .28), width: w * .2, height: h * .16),
        Paint()..color = const Color(0xFF120A2A));
    c.restore();
  }

  // ---------- enemies
  void _drawE(Enemy e) {
    final T = TY[e.t], im = T.img >= 0 ? A.mons[T.img] : null;
    if (!T.gh && im == null) return;
    final w = T.gh ? T.h * .8 : im!.width * T.h / im.height;
    final b = sin(g.t * (T.gh ? 3 : 5) + e.ph) * (T.fly || T.gh ? 5 : 2), lift = T.fly || T.gh ? 16.0 : 0.0;
    _shadow(e.x, e.y, w * .35, 5, .4);
    if (T.boss || T.mini) {
      _fill
        ..shader = null
        ..maskFilter = null
        ..color = T.boss ? const Color.fromRGBO(250, 204, 21, .22) : const Color.fromRGBO(239, 68, 68, .2);
      c.drawOval(Rect.fromCenter(center: Offset(e.x, e.y - T.h / 2), width: w * 1.4, height: T.h * 1.1), _fill);
    }
    c.save();
    c.translate(e.x, e.y - lift + b);
    if (T.fl && e.fx) c.scale(-1, 1);
    final flash = e.fl > 0;
    if (flash) c.saveLayer(null, Paint()..colorFilter = _brightness3);
    if (T.gh) {
      _ghost(T.h, w);
    } else {
      _full(im!, -w / 2, -T.h, w, T.h);
    }
    if (flash) c.restore();
    c.restore();
    final by = e.y - T.h - lift - 10, bw = max(30.0, w * .6);
    c.drawRect(Rect.fromLTWH(e.x - bw / 2 - 1, by - 1, bw + 2, 6), Paint()..color = Colors.black);
    c.drawRect(Rect.fromLTWH(e.x - bw / 2, by, bw * max(0.0, e.hp / e.mhp), 4),
        Paint()..color = e.hp / e.mhp > .4 ? const Color(0xFFE03A4E) : const Color(0xFFFB923C));
    if (T.boss) _text('👑', e.x, by - 6, 20, Colors.white);
    if (e.mode == 'wind' || (T.boss && (e.mode == 'burst' || e.mode == 'sum'))) {
      _text('!', e.x, by - (T.boss ? 28 : 4), 22, const Color(0xFFF43F5E));
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter old) => true;
}
