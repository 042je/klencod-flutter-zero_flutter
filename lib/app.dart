import 'package:flutter/material.dart';
import 'assets.dart';
import 'audio.dart';
import 'data.dart';
import 'game.dart';

enum Scr { menu, stages, skins, sett, how, game }

const kBg = Color(0xFF0D0D1A);
const kFg = Color(0xFFEDE9FE);
const kPur = Color(0xFF8B5CF6);
const kBox = Color.fromRGBO(22, 16, 44, .92);
const kLn = Color(0xFF4C3A8F);

class AppState extends ChangeNotifier {
  AppState(this.G, this.A) {
    au.snd = G.snd;
    au.mus = G.mus;
    game = Game(G, au, banner);
  }
  final Save G;
  final Assets A;
  final Audio au = Audio();
  late final Game game;
  Scr scr = Scr.menu;
  String bannerText = '';
  int bannerKey = 0;

  void go(Scr s) {
    au.start();
    if (s == Scr.stages || s == Scr.menu) {
      game.state = 'menu';
      game.atkHeld = false;
    }
    scr = s;
    notifyListeners();
  }

  void startStage(int n) {
    au.start();
    game.startStage(n);
    scr = Scr.game;
    notifyListeners();
  }

  void banner(String s) {
    bannerText = s;
    bannerKey++;
    notifyListeners();
  }

  /// Call after changing anything in [G].
  void changed() {
    G.write();
    au.snd = G.snd;
    au.mus = G.mus;
    au.applyMusic();
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);
  static AppState of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
