import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'assets.dart';
import 'data.dart';
import 'game_screen.dart';
import 'screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final save = await Save.read();
  final assets = await Assets.loadAll();
  runApp(ZeroApp(AppState(save, assets)));
}

class ZeroApp extends StatelessWidget {
  final AppState state;
  const ZeroApp(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: kBg, colorSchemeSeed: kPur),
      home: AppScope(state: state, child: const _Root()),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final Widget body;
    switch (app.scr) {
      case Scr.menu:
        body = const MenuScreen();
      case Scr.stages:
        body = const StagesScreen();
      case Scr.skins:
        body = const SkinsScreen();
      case Scr.sett:
        body = const SettScreen();
      case Scr.how:
        body = const HowScreen();
      case Scr.game:
        body = const GameScreen();
    }
    return Scaffold(
      backgroundColor: kBg,
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        Positioned.fill(child: DefaultTextStyle.merge(style: const TextStyle(color: kFg), child: body)),
        Positioned.fill(child: IgnorePointer(child: BannerOverlay(key: ValueKey(app.bannerKey), text: app.bannerText, show: app.bannerKey > 0))),
      ]),
    );
  }
}

class BannerOverlay extends StatefulWidget {
  final String text;
  final bool show;
  const BannerOverlay({super.key, required this.text, required this.show});
  @override
  State<BannerOverlay> createState() => _BannerState();
}

class _BannerState extends State<BannerOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();
    final h = MediaQuery.of(context).size.height, w = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final v = c.value, o = v < .12 ? v / .12 : (v < .8 ? 1.0 : (1 - v) / .2);
        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: h * .22),
              child: Container(
                constraints: BoxConstraints(maxWidth: w * .84),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                    color: const Color.fromRGBO(20, 10, 50, .88), border: Border.all(color: kPur, width: 2), borderRadius: BorderRadius.circular(16)),
                child: Text(widget.text,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 18, height: 1.7, color: kFg, decoration: TextDecoration.none, fontWeight: FontWeight.normal)),
              ),
            ),
          ),
        );
      },
    );
  }
}