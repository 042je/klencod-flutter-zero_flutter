import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'data.dart';
import 'widgets.dart';

// =====================================================================  MENU
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Container(
      color: kBg,
      child: SafeArea(
        child: LayoutBuilder(builder: (ctx, bc) {
          final h = min(bc.maxHeight, bc.maxWidth * 1280 / 688), w = h * 688 / 1280;
          Widget btn(Scr s, double l, double t, double bw, double bh) => Positioned(
                left: w * l / 100,
                top: h * t / 100,
                width: w * bw / 100,
                height: h * bh / 100,
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => app.go(s)),
              );
          return Center(
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(children: [
                Positioned.fill(child: Image.asset('assets/img/menu.jpg', fit: BoxFit.fill)),
                Positioned(
                  left: w * .06,
                  top: h * .228,
                  width: w * .88,
                  height: h * .068,
                  child: IgnorePointer(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: const Color.fromRGBO(24, 12, 60, .92), borderRadius: BorderRadius.circular(12)),
                      child: Text('الليل في المدينة مليء بالظلال. اجمع كرات الطاقة وهاجم الظلال بالسيف، وخلّص المراحل السبع!',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: min(w * .034, 14), height: 1.6, color: kFg, decoration: TextDecoration.none)),
                    ),
                  ),
                ),
                btn(Scr.stages, 30, 71, 40.2, 7.6),
                btn(Scr.skins, 8.2, 81.3, 25, 4.7),
                btn(Scr.sett, 36.2, 81.3, 25.8, 4.7),
                btn(Scr.how, 65.2, 81.3, 26, 4.7),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

// =====================================================================  STAGES
class StagesScreen extends StatefulWidget {
  const StagesScreen({super.key});
  @override
  State<StagesScreen> createState() => _StagesState();
}

class _StagesState extends State<StagesScreen> with SingleTickerProviderStateMixin {
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  static const SC = [[560, 1960, 125], [762, 1530, 102], [355, 1300, 98], [710, 1120, 98], [362, 925, 82], [738, 825, 84]];
  static const SY = [2130, 1690, 1455, 1265, 1070, 960];
  static const SS = [[120, 88], [90, 66], [90, 66], [90, 66], [90, 66], [90, 66]];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context), G = app.G;
    return Container(
      color: kBg,
      child: SafeArea(
        child: LayoutBuilder(builder: (ctx, bc) {
          final h = min(bc.maxHeight, bc.maxWidth * 2), w = h / 2;
          double u(num v) => w * v / 1120;
          Widget at(num x, num y, num bw, num bh, Widget child) =>
              Positioned(left: u(x - bw / 2), top: u(y - bh / 2), width: u(bw), height: u(bh), child: child);
          final kids = <Widget>[];
          kids.add(Positioned.fill(child: Image.asset('assets/img/stg.jpg', fit: BoxFit.fill)));
          // back
          kids.add(Positioned(
              left: w * .098 - w * .07,
              top: h * .127 - w * .04,
              width: w * .14,
              height: w * .08,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => app.go(Scr.menu))));
          for (var i = 0; i < 6; i++) {
            final cx = SC[i][0], cy = SC[i][1], r = SC[i][2], n = i + 1, un = n <= G.u;
            final col = n <= 4 ? const Color(0xFF3B82F6) : n == 5 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
            if (un && n > 1) {
              kids.add(at(
                  cx, cy, r * 2 + 3, r * 2 + 3,
                  IgnorePointer(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(center: const Alignment(-.3, -.4), radius: .8, colors: [Colors.white.withOpacity(.6), col], stops: const [0, .58]),
                        border: Border.all(color: const Color(0xFFFDE68A), width: w * .008),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.35), offset: Offset(0, w * .006)), BoxShadow(color: Colors.white.withOpacity(.25), blurRadius: w * .03)],
                      ),
                      child: StrokedText('$n', u(r * 1.15), Colors.white, Colors.black.withOpacity(.4), w * .008),
                    ),
                  )));
            }
            if (un && G.sr[i] == 0 && n > 1) {
              kids.add(at(
                  cx, cy, r * 2 + 30, r * 2 + 30,
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: pulse,
                      builder: (_, __) => Opacity(
                        opacity: .9 * (1 - pulse.value),
                        child: Transform.scale(
                          scale: 1 + .25 * pulse.value,
                          child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFDE047), width: w * .01))),
                        ),
                      ),
                    ),
                  )));
            }
            for (var s = 0; s < G.sr[i]; s++) {
              kids.add(at(cx + (s - 1) * SS[i][0], SY[i], SS[i][1] * 2, SS[i][1] * 2,
                  IgnorePointer(child: Center(child: StrokedText('★', u(SS[i][1] * 1.05), const Color(0xFFFBBF24), const Color(0xFF78350F), w * .01)))));
            }
            kids.add(at(cx, cy, r * 2, r * 2, GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _tap(app, n))));
          }
          // boss
          kids.add(at(565, 540, 420, 480, GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _tap(app, 7))));
          if (G.u >= 7) {
            kids.add(at(
                565, 400, 110, 110,
                IgnorePointer(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(center: Alignment(-.3, -.4), radius: .8, colors: [Color(0xFFFEF3C7), Color(0xFFD97706)], stops: [0, .7]),
                      border: Border.all(color: const Color(0xFFFDE68A), width: w * .008),
                    ),
                    child: Text('⚔️', style: TextStyle(fontSize: u(58), height: 1)),
                  ),
                )));
          }
          if (G.u >= 7 && G.sr[6] == 0) {
            kids.add(at(
                565, 540, 330, 330,
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: pulse,
                    builder: (_, __) => Opacity(
                      opacity: .9 * (1 - pulse.value),
                      child: Transform.scale(
                          scale: 1 + .25 * pulse.value,
                          child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFDE047), width: w * .01)))),
                    ),
                  ),
                )));
          }
          for (var s = 0; s < G.sr[6]; s++) {
            kids.add(at(565 + (s - 1) * 75, 660, 140, 140,
                IgnorePointer(child: Center(child: StrokedText('★', u(64), const Color(0xFFFBBF24), const Color(0xFF78350F), w * .01)))));
          }
          return Center(child: SizedBox(width: w, height: h, child: Stack(children: kids)));
        }),
      ),
    );
  }

  void _tap(AppState app, int n) {
    if (n <= app.G.u) {
      app.startStage(n);
    } else {
      app.banner('🔒 خلّص المرحلة اللي قبلها الأول');
    }
  }
}

// =====================================================================  SKINS
class SkinsScreen extends StatefulWidget {
  const SkinsScreen({super.key});
  @override
  State<SkinsScreen> createState() => _SkinsState();
}

class _SkinsState extends State<SkinsScreen> {
  String? failKey;

  void _press(AppState app, bool isChar, int i) {
    final G = app.G, price = isChar ? CH[i].p : SW[i].p, list = isChar ? G.oc : G.os;
    if (!list.contains(i)) {
      if (G.gems < price) {
        setState(() => failKey = '${isChar ? 'c' : 's'}$i');
        Timer(const Duration(milliseconds: 900), () {
          if (mounted) setState(() => failKey = null);
        });
        return;
      }
      G.gems -= price;
      list.add(i);
    }
    if (isChar) {
      G.c = i;
    } else {
      G.s = i;
    }
    app.changed();
  }

  Widget _card(AppState app, bool isChar, int i) {
    final G = app.G;
    final name = isChar ? CH[i].n : SW[i].n;
    final img = isChar ? 'assets/img/${CH[i].k}_down.webp' : 'assets/img/swords_$i.webp';
    final sel = isChar ? G.c == i : G.s == i, owned = (isChar ? G.oc : G.os).contains(i);
    final label = failKey == '${isChar ? 'c' : 's'}$i'
        ? '💎 ✖'
        : sel ? 'EQUIPPED' : owned ? 'EQUIP' : '💎 ${isChar ? CH[i].p : 'BUY'}';
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
            color: kBox,
            border: Border.all(color: sel ? const Color(0xFFC084FC) : kLn),
            borderRadius: BorderRadius.circular(10),
            boxShadow: sel ? [const BoxShadow(color: kPur, blurRadius: 12)] : null),
        child: Column(children: [
          SizedBox(height: 120, child: Image.asset(img, fit: BoxFit.contain)),
          const SizedBox(height: 4),
          Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kFg)),
          if (!isChar) Padding(padding: const EdgeInsets.only(top: 4), child: Text('💎 ${SW[i].p}', style: const TextStyle(fontSize: 11, color: kFg))),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _press(app, isChar, i),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                  color: (sel || owned) ? Colors.transparent : const Color(0xFF5B3FB5),
                  border: Border.all(color: kPur),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: (sel || owned) ? const Color(0xFFC4B5FD) : Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context), G = app.G;
    Widget h3(String s) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        child: Text(s, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFC4B5FD))));
    return Pg(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageTop('SKINS / السكنات', () => app.go(Scr.menu),
            trailing: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(color: kBox, border: Border.all(color: kLn), borderRadius: BorderRadius.circular(20)),
                child: Text('💎 ${G.gems}', style: const TextStyle(fontWeight: FontWeight.w700, color: kFg)))),
        h3('🦋 Character Skins'),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var i = 0; i < CH.length; i++) _card(app, true, i)]),
        h3('⚔️ Sword Skins'),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var i = 0; i < SW.length; i++) _card(app, false, i)]),
        h3('PREVIEW'),
        Container(
          height: 150,
          width: double.infinity,
          decoration: boxDeco(r: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset('assets/img/${CH[G.c].k}_down.webp', height: 130),
            const SizedBox(width: 6),
            Image.asset('assets/img/swords_${G.s}.webp', height: 130),
          ]),
        ),
      ]),
    );
  }
}

// =====================================================================  SETTINGS
class SettScreen extends StatefulWidget {
  const SettScreen({super.key});
  @override
  State<SettScreen> createState() => _SettState();
}

class _SettState extends State<SettScreen> {
  final List<TextEditingController> ctl = [];
  bool _init = false;

  void _sync(AppState app) {
    if (_init) return;
    _init = true;
    for (final s in app.G.en) ctl.add(TextEditingController(text: s));
  }

  @override
  void dispose() {
    for (final c in ctl) c.dispose();
    super.dispose();
  }

  Widget _tog(bool v, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 58,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: v ? kPur : const Color(0xFF2A2545), borderRadius: BorderRadius.circular(15)),
          child: Text(v ? 'ON' : 'OFF', style: TextStyle(fontWeight: FontWeight.w700, color: v ? Colors.white : const Color(0xFFAAAAAA))),
        ),
      );

  Widget _row(String label, Widget trailing, {double size = 16, Color color = kFg}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(label, style: TextStyle(fontSize: size, color: color))),
          trailing,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context), G = app.G;
    _sync(app);
    final pv = G.en.firstWhere((s) => s.trim().isNotEmpty, orElse: () => 'Stay strong!');
    return Pg(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageTop('SETTINGS / الاعدادات', () => app.go(Scr.menu)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: boxDeco(),
          child: Column(children: [
            _row('Sound', _tog(G.snd, () {
              G.snd = !G.snd;
              app.changed();
            })),
            _row(
                '🎵 Music',
                SizedBox(
                  width: 190,
                  child: Row(children: [
                    Expanded(
                        child: Slider(
                            value: G.mus.toDouble(),
                            min: 0,
                            max: 100,
                            activeColor: const Color(0xFFA855F7),
                            onChanged: (v) {
                              G.mus = v.round();
                              app.changed();
                            })),
                    Text('${G.mus}%', style: const TextStyle(color: kFg)),
                  ]),
                )),
            _row('Vibration', _tog(G.vib, () {
              G.vib = !G.vib;
              app.changed();
              if (G.vib) HapticFeedback.mediumImpact();
            })),
            _row('🎮 Controls', PBtn(G.flip ? 'Sides: R ⟷ L' : 'Sides: L ⟷ R', () {
              G.flip = !G.flip;
              app.changed();
            }, size: 13, vpad: 8, hpad: 14)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: boxDeco(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _row('✨ Encouragement Texts / نصوص تشجيعية', const SizedBox(), color: const Color(0xFFD8B4FE)),
            _row('Show encouragement when health is low', _tog(G.eo, () {
              G.eo = !G.eo;
              app.changed();
            }), size: 14),
            for (var i = 0; i < ctl.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TextField(
                  controller: ctl[i],
                  maxLength: 60,
                  style: const TextStyle(color: kFg, fontSize: 14),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Type your encouragement here...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF120D26),
                    contentPadding: const EdgeInsets.all(11),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kLn, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPur, width: 1.5)),
                  ),
                  onChanged: (v) {
                    G.en[i] = v;
                    G.write();
                    setState(() {});
                  },
                ),
              ),
            if (ctl.length < 8)
              GestureDetector(
                onTap: () {
                  G.en.add('');
                  ctl.add(TextEditingController());
                  app.changed();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(border: Border.all(color: kPur, width: 2), borderRadius: BorderRadius.circular(10)),
                  child: const Text('+ Add your own text', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        ),
        const Padding(
            padding: EdgeInsets.fromLTRB(4, 14, 4, 8),
            child: Text('Advice Bar Preview:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFC4B5FD)))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: boxDeco(),
          child: Row(children: [
            FaceWidget(app.A.chars[CH[G.c].k]!.down, 44),
            const SizedBox(width: 10),
            Expanded(child: Text(pv, style: const TextStyle(color: kFg))),
          ]),
        ),
      ]),
    );
  }
}

// =====================================================================  HOW TO PLAY
class HowScreen extends StatefulWidget {
  const HowScreen({super.key});
  @override
  State<HowScreen> createState() => _HowState();
}

class _HowState extends State<HowScreen> {
  int open = 1;
  int frame = 0;
  Timer? tm;

  @override
  void initState() {
    super.initState();
    tm = Timer.periodic(const Duration(milliseconds: 260), (_) {
      if (mounted) setState(() => frame++);
    });
  }

  @override
  void dispose() {
    tm?.cancel();
    super.dispose();
  }

  Widget _card(int i, String ic, String title, Widget body) {
    final o = open == i;
    return GestureDetector(
      onTap: () => setState(() => open = o ? -1 : i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: o ? const Color.fromRGBO(167, 100, 255, .45) : const Color.fromRGBO(255, 255, 255, .14),
            border: Border.all(color: o ? const Color(0xFFD8B4FE) : const Color.fromRGBO(255, 255, 255, .25), width: 2),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Color.fromRGBO(40, 20, 120, .35), offset: Offset(0, 5))]),
        child: Column(children: [
          Row(children: [
            Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, .2), borderRadius: BorderRadius.circular(12)),
                child: Text(ic, style: const TextStyle(fontSize: 24))),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white))),
            Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFF7C4DDD), shape: BoxShape.circle),
                child: Icon(o ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white)),
          ]),
          if (o) Padding(padding: const EdgeInsets.only(top: 12), child: Directionality(textDirection: TextDirection.rtl, child: body)),
        ]),
      ),
    );
  }

  static const _body = TextStyle(fontSize: 14, height: 1.8, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context), G = app.G, k = CH[G.c].k;
    final walkFrames = k == 'hijab' ? 4 : 0;
    final hg = walkFrames > 0 ? 'assets/img/hijab_walk_${frame % 4}.webp' : 'assets/img/${k}_down.webp';
    const mons = [
      ['Dark Butterfly', 'mons_1', 'طيران متعرج يصعّب إصابته'],
      ['Night Wolf', 'mons_2', 'بيلف حواليك وبعدين يهجم بقفزة'],
      ['Thorn Demon', 'mons_3', 'بيبعد عنك وبيضرب كرات نار'],
      ['Bone Skeleton', 'mons_4', 'الأذكى: بيتوقعك ويتفادى ضرباتك'],
    ];
    Widget mr(Widget lead, String n, String d) => Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: const Color.fromRGBO(0, 0, 0, .18), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            SizedBox(width: 56, height: 56, child: Center(child: lead)),
            const SizedBox(width: 10),
            Expanded(child: Text.rich(TextSpan(children: [TextSpan(text: n, style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: '\n$d')]), style: _body.copyWith(fontSize: 13, height: 1.5))),
          ]),
        );
    return Pg(
      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4C32C4), Color(0xFF7C4DDD), Color(0xFF9B6CF0)], stops: [0, .55, 1]),
      child: Column(children: [
        PageTop('HOW TO PLAY', () => app.go(Scr.menu)),
        _card(0, '🏃', 'MOVEMENT · الحركة',
            Column(children: [
              const Text('استخدم الجويستيك على الشاشة (أو WASD / الأسهم) لتحريك الشخصية. الشخصية بتبص في اتجاه مشيك، والضربة بتطلع في نفس الاتجاه.', style: _body),
              Image.asset(hg, height: 170, gaplessPlayback: true),
            ])),
        _card(1, '⚔️', 'ATTACK & ENERGY · الضرب والطاقة',
            Column(children: [
              const Text('زر ⚔️ بيضرب بالسيف وبياخد 3 طاقة. الطاقة مبتزيدش لوحدها: اجمع كرات الطاقة البنفسجي (+30)، وكل وحش بيسيب كرة لما يموت. وكرات العلاج الخضرا 💚 على الأرض بترجّعلك صحتك.', style: _body),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset('assets/img/how.jpg')),
            ])),
        _card(2, '👻', 'AVOID THE MONSTERS · الوحوش',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final m in mons) mr(Image.asset('assets/img/${m[1]}.webp', fit: BoxFit.contain), m[0], m[2]),
              mr(const Text('👻', style: TextStyle(fontSize: 38)), 'Shadow Ghost', 'بيطفو ويطاردك في خط مستقيم'),
              const Text('كل وحش ليه دم، والأقوى أذكى. خلي بالك من علامة ❗ قبل الهجمة.', style: _body),
            ])),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color.fromRGBO(0, 0, 0, .25), borderRadius: BorderRadius.circular(20)),
          child: const Text('💡 TIP: 7 مراحل، والزعيم في الآخر. كل مرحلة بتدّيك حاجة جديدة، والجواهر 💎 بتشتري سكنات وسيوف.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white)),
        ),
      ]),
    );
  }
}
