import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'data.dart';
import 'game.dart';
import 'painter.dart';
import 'widgets.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<int> frame = ValueNotifier(0);
  Duration _last = Duration.zero;
  AppState? _app;
  GamePainter? _painter;
  final FocusNode _focus = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_app == null) {
      _app = AppScope.of(context);
      _painter = GamePainter(_app!.game, _app!.A, frame);
      _ticker = createTicker((d) {
        final g = _app!.game;
        final dt = min(.05, (d - _last).inMicroseconds / 1e6);
        _last = d;
        if (g.state == 'play') g.step(dt);
        frame.value++;
        // keep the "game over" overlay in sync
        if (_wasOver != (g.state == 'over')) {
          _wasOver = g.state == 'over';
          setState(() {});
        }
      })..start();
    }
  }

  bool _wasOver = false;

  @override
  void dispose() {
    _ticker.dispose();
    _focus.dispose();
    frame.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    final g = _app!.game;
    if (e is KeyDownEvent) {
      g.keys.add(e.logicalKey);
      if (e.logicalKey == LogicalKeyboardKey.space) {
        g.atkHeld = true;
        g.attack();
      }
      if (e.logicalKey == LogicalKeyboardKey.keyE || e.logicalKey == LogicalKeyboardKey.shiftLeft) g.dash();
    } else if (e is KeyUpEvent) {
      g.keys.remove(e.logicalKey);
      if (e.logicalKey == LogicalKeyboardKey.space) g.atkHeld = false;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context), g = app.game, G = app.G;
    final mq = MediaQuery.of(context);
    final top = mq.padding.top, bottom = mq.padding.bottom;
    final flip = G.flip;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _key,
      child: Container(
        color: kBg,
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _painter)),
          // ---- HUD (top-left)
          Positioned(
            top: top + 8,
            left: 8,
            child: ValueListenableBuilder<int>(
              valueListenable: frame,
              builder: (_, __, ___) => _hud(app, g),
            ),
          ),
          // ---- score (top-right)
          Positioned(
            top: top + 8,
            right: 8,
            child: ValueListenableBuilder<int>(
              valueListenable: frame,
              builder: (_, __, ___) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: boxDeco(r: 10),
                child: Text(
                    'المرحلة ${g.stg} · 🌊 ${max(1, g.wv + 1)}/${g.S.w.length}\n☠ ${g.E.length + g.wq.length} · 💎 ${G.gems}',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: kFg, decoration: TextDecoration.none, fontWeight: FontWeight.normal)),
              ),
            ),
          ),
          // ---- pause
          Positioned(
            top: top + 70,
            right: 8,
            child: GestureDetector(
              onTap: () => app.go(Scr.stages),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: boxDeco(r: 10),
                child: const Text('⏸', style: TextStyle(fontSize: 18, decoration: TextDecoration.none)),
              ),
            ),
          ),
          // ---- advice bar
          Positioned(
            top: top + 74,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<int>(
              valueListenable: frame,
              builder: (_, __, ___) => g.advShow
                  ? Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: mq.size.width * .78),
                        padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
                        decoration: BoxDecoration(
                            color: kBox,
                            border: Border.all(color: kPur, width: 2),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [BoxShadow(color: kPur, blurRadius: 14)]),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          FaceWidget(app.A.chars[CH[G.c].k]!.down, 36),
                          const SizedBox(width: 8),
                          Flexible(
                              child: Text(g.advText,
                                  style: const TextStyle(fontSize: 13, color: kFg, decoration: TextDecoration.none, fontWeight: FontWeight.normal))),
                        ]),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // ---- controls
          Positioned(
            bottom: bottom + 28,
            left: flip ? null : 18,
            right: flip ? 18 : null,
            child: Joystick(onChange: (x, y) {
              g.jx = x;
              g.jy = y;
            }),
          ),
          Positioned(
            bottom: bottom + 40,
            left: flip ? 22 : null,
            right: flip ? null : 22,
            child: _AttackButton(
              onDown: () {
                app.au.start();
                g.atkHeld = true;
                g.attack();
              },
              onUp: () => g.atkHeld = false,
            ),
          ),
          if (G.dash)
            Positioned(
              bottom: bottom + 148,
              left: flip ? 34 : null,
              right: flip ? null : 34,
              child: Listener(
                onPointerDown: (_) => g.dash(),
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromRGBO(56, 189, 248, .35),
                      border: Border.all(color: const Color(0xFF38BDF8), width: 3)),
                  child: const Text('💨', style: TextStyle(fontSize: 28, decoration: TextDecoration.none)),
                ),
              ),
            ),
          // ---- end-of-stage panel
          if (g.state == 'over') _panel(app, g),
        ]),
      ),
    );
  }

  Widget _hud(AppState app, Game g) {
    final P = g.P;
    Widget bar(double v, Color c, {bool low = false}) => Container(
          width: 110,
          height: 12,
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(3),
              border: low ? Border.all(color: const Color(0xFFF43F5E), width: 2) : null),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(children: [
              FractionallySizedBox(widthFactor: (v / 100).clamp(0.0, 1.0), child: Container(color: c)),
              Center(
                  child: Text('${max(0, v).ceil()}/100',
                      style: const TextStyle(fontSize: 9, color: Colors.white, height: 1.2, decoration: TextDecoration.none, fontWeight: FontWeight.normal))),
            ]),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: boxDeco(r: 10),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kPur, width: 2)),
            child: ClipOval(child: FaceWidget(app.A.chars[CH[app.G.c].k]!.down, 40))),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Lv.${g.stg}', style: const TextStyle(fontSize: 12, color: kFg, decoration: TextDecoration.none, fontWeight: FontWeight.normal)),
          bar(P.hp, const Color(0xFFE03A4E)),
          bar(P.mp, const Color(0xFF3B82F6), low: g.mpLowT > 0),
        ]),
      ]),
    );
  }

  Widget _panel(AppState app, Game g) {
    return Positioned.fill(
      child: Container(
        color: const Color.fromRGBO(8, 8, 20, .9),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(g.panelH,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFC4B5FD), decoration: TextDecoration.none)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(g.panelP,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 15, height: 1.8, color: kFg, decoration: TextDecoration.none, fontWeight: FontWeight.normal)),
            ),
            const SizedBox(height: 12),
            PBtn('إعادة', () => app.startStage(g.stg)),
            if (g.panelNext) ...[const SizedBox(height: 12), PBtn('المرحلة التالية ▶', () => app.startStage(g.stg + 1))],
            const SizedBox(height: 12),
            PBtn('المراحل', () => app.go(Scr.stages), color: const Color(0xFF2A2545)),
          ]),
        ),
      ),
    );
  }
}

class Joystick extends StatefulWidget {
  final void Function(double, double) onChange;
  const Joystick({super.key, required this.onChange});
  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset knob = Offset.zero;
  int? _id;

  void _move(Offset local) {
    var d = local - const Offset(65, 65);
    const m = 55.0;
    if (d.distance > m) d = d * (m / d.distance);
    setState(() => knob = d);
    widget.onChange(d.dx / m, d.dy / m);
  }

  void _end() {
    _id = null;
    setState(() => knob = Offset.zero);
    widget.onChange(0, 0);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (e) {
          _id = e.pointer;
          _move(e.localPosition);
        },
        onPointerMove: (e) {
          if (e.pointer == _id) _move(e.localPosition);
        },
        onPointerUp: (e) {
          if (e.pointer == _id) _end();
        },
        onPointerCancel: (e) {
          if (e.pointer == _id) _end();
        },
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(255, 255, 255, .08),
              border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2), width: 2)),
          child: Stack(children: [
            Positioned(
              left: 45 + knob.dx,
              top: 45 + knob.dy,
              child: Container(
                  width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(139, 92, 246, .75))),
            ),
          ]),
        ),
      );
}

class _AttackButton extends StatefulWidget {
  final VoidCallback onDown, onUp;
  const _AttackButton({required this.onDown, required this.onUp});
  @override
  State<_AttackButton> createState() => _AttackButtonState();
}

class _AttackButtonState extends State<_AttackButton> {
  bool on = false;
  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) {
          setState(() => on = true);
          widget.onDown();
        },
        onPointerUp: (_) {
          setState(() => on = false);
          widget.onUp();
        },
        onPointerCancel: (_) {
          setState(() => on = false);
          widget.onUp();
        },
        child: Transform.scale(
          scale: on ? .93 : 1,
          child: Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? const Color.fromRGBO(196, 132, 252, .8) : const Color.fromRGBO(139, 92, 246, .4),
                border: Border.all(color: kPur, width: 3)),
            child: const Text('⚔️', style: TextStyle(fontSize: 38, decoration: TextDecoration.none)),
          ),
        ),
      );
}
