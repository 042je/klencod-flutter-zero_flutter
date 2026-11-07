import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

final Random rng = Random();
double rnd(double a, double b) => a + rng.nextDouble() * (b - a);

const double WW = 1920, WH = 1280, ATK = .35;
const Map<String, List<double>> DIRS = {
  'down': [0, 1],
  'up': [0, -1],
  'left': [-1, 0],
  'right': [1, 0],
};

class CharDef {
  final String n, k;
  final int p;
  final bool sf; // sprite faces left by default on side view
  const CharDef(this.n, this.k, this.p, this.sf);
}

const List<CharDef> CH = [
  CharDef('Purple Classic', 'purple', 0, true),
  CharDef('Pink Cherry Blossom', 'pink', 800, true),
  CharDef('Black & Gold Midnight', 'black', 1500, false),
  CharDef('White Hijab', 'hijab', 1000, true),
];

class SwordDef {
  final String n;
  final int p, d, r;
  final Color c;
  const SwordDef(this.n, this.p, this.d, this.r, this.c);
}

const List<SwordDef> SW = [
  SwordDef('Purple Butterfly Katana', 1200, 8, 76, Color(0xFFA855F7)),
  SwordDef('Pink Sakura Katana', 1500, 9, 84, Color(0xFFF9A8D4)),
  SwordDef('Black Golden Katana', 1800, 12, 80, Color(0xFFFBBF24)),
  SwordDef('Midnight Flower Katana', 2000, 16, 88, Color(0xFFE879F9)),
];

class MonType {
  final double h, hp, s0, s1, dm;
  final bool gh, fly, fl, boss, mini;
  final int img; // index into monster images, -1 = drawn in code
  const MonType(this.h, this.hp, this.s0, this.s1, this.dm,
      {this.gh = false, this.fly = false, this.fl = false, this.boss = false, this.mini = false, this.img = -1});
}

const List<MonType> TY = [
  MonType(74, 30, 35, 50, 8, gh: true),
  MonType(80, 20, 75, 95, 7, fly: true, img: 1),
  MonType(76, 45, 80, 95, 11, fl: true, img: 2),
  MonType(88, 65, 50, 65, 13, img: 3),
  MonType(128, 90, 42, 52, 18, img: 4),
  MonType(240, 700, 50, 60, 24, boss: true, img: 4),
  MonType(190, 230, 40, 50, 20, mini: true, img: 4),
];
const List<double> IQ = [.1, .3, .55, .75, .95, 1, .95];

const List<List<double>> TR = [
  [340, 315], [1185, 245], [1185, 630], [530, 800], [1590, 835]
];
const List<List<double>> RC = [
  [75, 940, 290, 1190],
  [1455, 880, 1860, 1280]
];
bool blocked(double x, double y, double r) {
  for (final q in TR) {
    if (sqrt((q[0] - x) * (q[0] - x) + (q[1] - y) * (q[1] - y)) < 20 + r) return true;
  }
  for (final b in RC) {
    if (x > b[0] - r && x < b[2] + r && y > b[1] - r && y < b[3] + r) return true;
  }
  return false;
}

class Reward {
  final int g;
  final int? sw, ch;
  final bool dash;
  final String txt;
  const Reward(this.g, this.txt, {this.sw, this.ch, this.dash = false});
}

class StageDef {
  final String n, d, intro;
  final List<List<int>> w;
  final List<double> pos;
  final Color tint;
  final Reward rw;
  const StageDef(this.n, this.d, this.w, this.pos, this.tint, this.rw, this.intro);
}

const List<StageDef> ST = [
  StageDef('التدريب', 'EASY', [[0, 0], [0, 0, 0]], [940, 640], Color.fromRGBO(20, 8, 60, .10),
      Reward(60, 'مكافأة 💎'), 'تحرك بالجويستيك واضرب الأشباح.\nخُد كرات العلاج الخضرا 💚 من الأرض.'),
  StageDef('البداية الحقيقية', 'NORMAL', [[0, 0, 1], [1, 1, 0], [0, 1, 1, 0]], [770, 300],
      Color.fromRGBO(20, 8, 60, .14), Reward(100, 'فتحت سيف Pink Sakura ⚔️', sw: 1), 'وحوش أسرع وبييجوا مع بعض.'),
  StageDef('الصعوبة بتبدأ', 'NORMAL', [[0, 1, 3], [2, 2, 3], [3, 4, 1]], [1040, 950],
      Color.fromRGBO(30, 8, 70, .18), Reward(140, 'فتحت الاندفاع 💨', dash: true), 'وحش بيضرب من بعيد ووحش دمه كتير!'),
  StageDef('النخبة', 'NORMAL', [[0, 0, 1, 1, 2], [2, 2, 3, 3], [6, 1, 1, 3]], [600, 520],
      Color.fromRGBO(40, 8, 70, .2), Reward(200, 'فتحت سيف Black Golden ⚔️', sw: 2),
      'وحوش كتير + وحش قوي.\nالتقط كرات العلاج 💚 من الأرض.'),
  StageDef('مرحلة صعبة', 'HARD', [[2, 2, 3, 3], [4, 1, 1, 3], [2, 2, 4, 3, 3]], [1480, 260],
      Color.fromRGBO(60, 8, 60, .22), Reward(260, 'فتحت سكن Pink Cherry Blossom 🌸', ch: 1), 'هجمات منظمة. استخدم الاندفاع 💨'),
  StageDef('مرحلة صعبة 2', 'HARD', [[3, 3, 2, 2, 4], [4, 4, 3, 1, 1, 0], [6, 6, 3, 3, 2]], [1650, 520],
      Color.fromRGBO(80, 8, 50, .26), Reward(320, 'فتحت سيف Midnight Flower ⚔️', sw: 3), 'قبل الزعيم… جهّز نفسك!'),
  StageDef('الزعيم', 'BOSS', [[5]], [960, 640], Color.fromRGBO(90, 0, 40, .3),
      Reward(600, 'فتحت سكن Black & Gold 👑', ch: 2), 'ملك الهياكل 👑\nبيهاجم بـ3 حركات مختلفة!'),
];

/// Persistent player data (mirrors the `G` object of the HTML version).
class Save {
  int u = 1;
  List<int> sr = List.filled(7, 0);
  bool dash = false;
  int gems = 3000;
  List<int> oc = [0], os = [0];
  int c = 0, s = 0;
  bool snd = true, vib = false, eo = true, flip = false;
  int mus = 70;
  List<String> en = ['Stay strong! You got this — keep fighting!', 'لا تستسلم، انت أقوى من الظلال!', ''];

  Map<String, dynamic> toJson() => {
        'u': u, 'sr': sr, 'dash': dash, 'gems': gems, 'oc': oc, 'os': os, 'c': c, 's': s,
        'snd': snd, 'mus': mus, 'vib': vib, 'eo': eo, 'flip': flip, 'en': en,
      };

  void load(Map<String, dynamic> j) {
    List<int> li(dynamic v, List<int> d) => v is List ? v.map((e) => (e as num).toInt()).toList() : d;
    u = (j['u'] as num?)?.toInt() ?? u;
    final r = li(j['sr'], sr);
    sr = List.generate(7, (i) => i < r.length ? r[i] : 0);
    dash = j['dash'] == true || j['dash'] == 1;
    gems = (j['gems'] as num?)?.toInt() ?? gems;
    oc = li(j['oc'], oc);
    os = li(j['os'], os);
    c = (j['c'] as num?)?.toInt() ?? c;
    s = (j['s'] as num?)?.toInt() ?? s;
    snd = j['snd'] == null ? snd : (j['snd'] == true || j['snd'] == 1);
    mus = (j['mus'] as num?)?.toInt() ?? mus;
    vib = j['vib'] == true || j['vib'] == 1;
    eo = j['eo'] == null ? eo : (j['eo'] == true || j['eo'] == 1);
    flip = j['flip'] == true || j['flip'] == 1;
    if (j['en'] is List) en = (j['en'] as List).map((e) => '$e').toList();
  }

  static Future<Save> read() async {
    final s = Save();
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString('zero');
      if (raw != null) s.load(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
    return s;
  }

  Future<void> write() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('zero', jsonEncode(toJson()));
    } catch (_) {}
  }
}
