import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'audio.dart';
import 'data.dart';

class Player {
  double x, y, vx = 0, vy = 0, hp = 100, mp = 100, inv = 0, sp = 135, walk = 0, atkT = 0, cd = 0, dashT = 0, dc = 0;
  double mdx = 0, mdy = 1;
  String dir = 'down';
  bool moving = false;
  Player(this.x, this.y);
}

class Enemy {
  int t;
  double x, y, hp, mhp, sp, dm, ph;
  double fl = 0, kx = 0, ky = 0;
  bool fx = false, dead = false;
  String mode = 'ring';
  double ang;
  int dir;
  double tm, shot, dg = 0;
  int dd = 1;
  double lx = 0, ly = 0, sm = 0;
  Enemy(this.t, this.x, this.y, this.hp, this.sp, this.dm, this.ph, this.ang, this.dir, this.tm, this.shot)
      : mhp = hp;
}

class Orb {
  double x, y, ph;
  bool got = false;
  Orb(this.x, this.y, this.ph);
}

class Proj {
  double x, y, vx, vy, t;
  Proj(this.x, this.y, this.vx, this.vy, this.t);
}

class Fx {
  String k;
  double x, y, vx, vy, t, m, a;
  Color c;
  String v;
  bool cr, g;
  Fx(this.k, {this.x = 0, this.y = 0, this.vx = 0, this.vy = 0, required this.t, this.m = 0, this.a = 0,
      this.c = Colors.white, this.v = '', this.cr = false, this.g = false});
}

/// Whole game simulation (port of the JS `step`, `ai`, `boss`, `attack`, `waves`, ...).
class Game {
  final Save G;
  final Audio au;
  final void Function(String) banner;
  Game(this.G, this.au, this.banner);

  int stg = 1;
  String state = 'menu'; // menu | play | over
  late Player P = Player(0, 0);
  List<Enemy> E = [];
  List<Orb> O = [], HO = [];
  List<Fx> fx = [];
  List<Proj> PR = [];
  int score = 0;
  double t = 0, shake = 0, advT = 0, spT = 0, wDelay = 0, hoT = 4, mpLowT = 0;
  bool atkHeld = false, camSnap = true;
  double camX = 0, camY = 0;
  int wv = -1;
  List<int> wq = [];
  double jx = 0, jy = 0;
  final Set<LogicalKeyboardKey> keys = {};
  String advText = '';
  bool advShow = false;
  String panelH = '', panelP = '';
  bool panelNext = false;

  StageDef get S => ST[stg - 1];

  void sfx(String n) => au.sfx(n);
  void vib(int ms) {
    if (G.vib) HapticFeedback.mediumImpact();
  }

  // ---------- setup
  void reset() {
    P = Player(S.pos[0], S.pos[1]);
    E = [];
    O = [];
    fx = [];
    PR = [];
    HO = [];
    score = 0;
    camSnap = true;
    wv = -1;
    wq = [];
    spT = 0;
    wDelay = 1.8;
    hoT = stg == 1 ? 2 : 5;
    advT = 0;
    for (var i = 0; i < 4; i++) spawnO(P.x + rnd(-150, 150), P.y + rnd(-150, 150));
    for (var i = 0; i < 5; i++) spawnO();
  }

  void startStage(int n) {
    stg = n;
    reset();
    state = 'play';
    banner('المرحلة $n — ${S.n}\n${S.intro}');
  }

  void mk(int ti, double x, double y) {
    final T = TY[ti];
    final hm = (1 + .2 * (stg - 1)) * (stg == 1 ? .7 : 1);
    final sm = (1 + .07 * (stg - 1)) * (stg == 1 ? .8 : 1);
    final dmm = stg == 1 ? .5 : 1 + .12 * (stg - 1);
    final hp = T.boss ? T.hp : T.hp * hm;
    E.add(Enemy(ti, x, y, hp, rnd(T.s0, T.s1) * sm, T.dm * dmm, rnd(0, 6), atan2(y - P.y, x - P.x),
        rng.nextBool() ? 1 : -1, rnd(1, 2.5), rnd(1, 2.5)));
  }

  void spawnT(int ti) {
    for (var k = 0; k < 40; k++) {
      final a = rnd(0, 6.28), r = rnd(280, 380), x = P.x + cos(a) * r, y = P.y + sin(a) * r;
      if ((x > 40 && x < WW - 40 && y > 80 && y < WH - 20 && !blocked(x, y, 14)) || k == 39) {
        mk(ti, x.clamp(40, WW - 40).toDouble(), y.clamp(80, WH - 20).toDouble());
        return;
      }
    }
  }

  void spawnAt(int ti, double x, double y) =>
      mk(ti, x.clamp(40, WW - 40).toDouble(), y.clamp(80, WH - 20).toDouble());

  void spawnO([double? px, double? py]) {
    double x, y;
    if (px == null || py == null) {
      do {
        x = rnd(40, WW - 40);
        y = rnd(60, WH - 40);
      } while (blocked(x, y, 10));
    } else {
      x = px;
      y = py;
      if (blocked(x, y, 10) || x < 20 || y < 40 || x > WW - 20 || y > WH - 20) {
        x = P.x;
        y = P.y + 40;
      }
    }
    O.add(Orb(x, y, rnd(0, 6)));
  }

  /// Healing orb that lies on the ground (replaces the old helper girl).
  void spawnH(double x, double y) {
    if (blocked(x, y, 10) || x < 20 || y < 40 || x > WW - 20 || y > WH - 20) {
      x = P.x + rnd(-40, 40);
      y = P.y + 40;
    }
    HO.add(Orb(x, y, rnd(0, 6)));
  }

  List<double> hand() {
    switch (P.dir) {
      case 'right':
        return [6, -50];
      case 'left':
        return [-6, -50];
      case 'down':
        return [16, -50];
      default:
        return [16, -52];
    }
  }

  // ---------- player actions
  void attack() {
    if (state != 'play' || P.cd > 0) return;
    if (P.mp < 3) {
      mpLowT = .25;
      return;
    }
    final sw = SW[G.s], d = DIRS[P.dir]!, h = hand(), ox = P.x + h[0], oy = P.y + h[1];
    P.mp -= 3;
    P.cd = ATK;
    P.atkT = ATK;
    sfx('atk');
    fx.add(Fx('slash', a: atan2(d[1], d[0]), t: .24, m: .24, c: sw.c, x: ox, y: oy));
    for (final e in List<Enemy>.of(E)) {
      final T = TY[e.t], dx = e.x - ox, dy = e.y - T.h / 2 - oy;
      final dist = sqrt(dx * dx + dy * dy);
      final dd = dist == 0 ? 1.0 : dist;
      if (dd < sw.r + T.h * .3 && (dx * d[0] + dy * d[1]) > dd * .15) {
        var dm = sw.d * rnd(.85, 1.15);
        final cr = rng.nextDouble() < .12;
        if (cr) dm *= 1.7;
        dm = dm.roundToDouble();
        e.hp -= dm;
        e.fl = .12;
        final kb = 14 * (1 - IQ[e.t] * .5);
        e.kx = dx / dd * kb;
        e.ky = dy / dd * kb;
        shake = 5;
        sfx('hit');
        fx.add(Fx('dm', x: e.x, y: e.y - T.h - 4, v: '${dm.toInt()}', cr: cr, t: .7));
        if (e.hp <= 0) {
          e.dead = true;
          score++;
          G.gems += 5;
          spawnO(e.x, e.y);
          if (rng.nextDouble() < .18) spawnH(e.x, e.y);
          burst(e.x, e.y - T.h / 2);
          sfx('kill');
        }
      }
    }
    E.removeWhere((e) => e.dead);
  }

  void burst(double x, double y) {
    for (var i = 0; i < 12; i++) {
      fx.add(Fx('p', x: x, y: y, vx: rnd(-90, 90), vy: rnd(-90, 90), t: .5));
    }
  }

  void dash() {
    if (state != 'play' || !G.dash || P.dc > 0) return;
    if (!P.moving) {
      P.mdx = DIRS[P.dir]![0];
      P.mdy = DIRS[P.dir]![1];
    }
    P.dashT = .2;
    P.dc = 1.2;
    P.inv = max(P.inv, .35);
    sfx('dash');
  }

  // ---------- enemy AI
  void boss(Enemy e, MonType T, double dt, double ux, double uy) {
    final hpr = e.hp / e.mhp, sp = e.sp * (hpr < .5 ? 1.25 : 1), cy = e.y - T.h / 2;
    double mx = 0, my = 0;
    if (e.mode == 'ring') {
      e.ang += dt * e.dir * .6;
      final gx = P.x + cos(e.ang) * 130 - e.x, gy = P.y - 35 + sin(e.ang) * 130 - cy;
      final gd = sqrt(gx * gx + gy * gy);
      final g = gd == 0 ? 1.0 : gd;
      mx = gx / g;
      my = gy / g;
      if (e.tm <= 0) {
        final sum = e.sm <= 0 && !E.any((o) => o.t == 0);
        e.mode = sum ? 'sum' : (rng.nextDouble() < .45 ? 'wind' : 'burst');
        e.tm = .7;
        e.lx = ux;
        e.ly = uy;
      }
    } else if (e.mode == 'wind') {
      e.lx = ux;
      e.ly = uy;
      if (e.tm <= 0) {
        e.mode = 'lunge';
        e.tm = .3;
      }
    } else if (e.mode == 'lunge') {
      mx = e.lx;
      my = e.ly;
      if (e.tm <= 0) {
        e.mode = 'rest';
        e.tm = .8;
      }
    } else if (e.mode == 'burst') {
      if (e.tm <= 0) {
        final n = hpr < .5 ? 14 : 10, o = rnd(0, 6.28);
        for (var i = 0; i < n; i++) {
          final a = o + i * 6.283 / n;
          PR.add(Proj(e.x, cy, cos(a) * 130, sin(a) * 130, 3.5));
        }
        sfx('burst');
        e.mode = 'rest';
        e.tm = 1;
      }
    } else if (e.mode == 'sum') {
      if (e.tm <= 0) {
        spawnAt(0, e.x - 70, e.y);
        spawnAt(0, e.x + 70, e.y);
        e.sm = 9;
        e.mode = 'rest';
        e.tm = .8;
      }
    } else if (e.tm <= 0) {
      e.mode = 'ring';
      e.tm = rnd(1.2, 2.2);
      e.ang = atan2(cy - (P.y - 35), e.x - P.x);
    }
    e.sm -= dt;
    final v = sp * (e.mode == 'lunge' ? 4.2 : 1);
    e.x += mx * v * dt;
    e.y += my * v * dt;
    e.fx = P.x > e.x;
  }

  void ai(Enemy e, MonType T, double dt) {
    final q = IQ[e.t], ex = e.x, ey = e.y - T.h / 2, ty = P.y - 35;
    final dx = P.x + P.vx * q * .6 - ex, dy = ty + P.vy * q * .6 - ey;
    final dr = sqrt(dx * dx + dy * dy), d = dr == 0 ? 1.0 : dr, ux = dx / d, uy = dy / d;
    double mx = ux, my = uy, s = e.sp;
    e.dg -= dt;
    e.tm -= dt;
    e.shot -= dt;
    if (e.t == 5) {
      boss(e, T, dt, ux, uy);
      return;
    }
    if (q >= .5 && e.dg <= 0 && P.atkT > 0 && d < 120 && e.mode == 'ring' && rng.nextDouble() < q * dt * 6) {
      e.dg = .3;
      e.dd = rng.nextBool() ? 1 : -1;
    }
    if (e.dg > 0) {
      mx = -uy * e.dd;
      my = ux * e.dd;
      s *= 2.2;
    } else if (e.t == 1) {
      final w = sin(t * 5 + e.ph);
      mx = ux - uy * w * .9;
      my = uy + ux * w * .9;
    } else if (e.t == 3) {
      if (d < 120) {
        mx = -ux;
        my = -uy;
        s *= 1.2;
      } else if (d <= 200) {
        mx = -uy * e.dir;
        my = ux * e.dir;
        s *= .8;
      }
      if (e.shot <= 0 && d < 280) {
        final a = atan2(dy, dx);
        PR.add(Proj(ex, ey, cos(a) * 150, sin(a) * 150, 3));
        e.shot = 2.4;
        sfx('shoot');
      }
    } else if (e.t >= 2) {
      if (e.mode == 'ring') {
        final R = T.h * .8;
        e.ang += dt * e.dir * .9;
        final gx = P.x + cos(e.ang) * R - ex, gy = ty + sin(e.ang) * R - ey;
        final gdr = sqrt(gx * gx + gy * gy), gd = gdr == 0 ? 1.0 : gdr;
        mx = gx / gd;
        my = gy / gd;
        if (e.tm <= 0 && d < R * 2.2) {
          e.mode = 'wind';
          e.tm = e.t >= 4 ? .55 : .4;
        }
      } else if (e.mode == 'wind') {
        mx = my = 0;
        e.lx = ux;
        e.ly = uy;
        if (e.tm <= 0) {
          e.mode = 'lunge';
          e.tm = .28;
        }
      } else if (e.mode == 'lunge') {
        mx = e.lx;
        my = e.ly;
        s *= 3.4;
        if (e.tm <= 0) {
          e.mode = 'rest';
          e.tm = .7;
        }
      } else {
        mx = my = 0;
        if (e.tm <= 0) {
          e.mode = 'ring';
          e.tm = rnd(1, 2.2);
          e.ang = atan2(ey - ty, ex - P.x);
        }
      }
    }
    e.x += mx * s * dt;
    e.y += my * s * dt;
    e.fx = dx > 0;
  }

  // ---------- waves
  void waves(double dt) {
    if (spT > 0) spT -= dt;
    if (wq.isNotEmpty) {
      if (spT <= 0) {
        spawnT(wq.removeAt(0));
        spT = stg == 1 ? 1.1 : .75;
      }
      return;
    }
    if (E.isNotEmpty) return;
    if (wDelay > 0) {
      wDelay -= dt;
      return;
    }
    if (wv >= 0 && wv + 1 >= S.w.length) {
      win();
      return;
    }
    wv++;
    wq = List<int>.of(S.w[wv]);
    banner(stg == 7 ? '👑 الزعيم!' : '🌊 Wave ${wv + 1} / ${S.w.length}');
    for (var i = 0; i < 5; i++) spawnO();
    wDelay = 2.2;
  }

  // ---------- main step
  bool _k(LogicalKeyboardKey a, [LogicalKeyboardKey? b]) => keys.contains(a) || (b != null && keys.contains(b));

  void step(double dt) {
    t += dt;
    P.cd -= dt;
    P.inv -= dt;
    P.dc -= dt;
    P.atkT = max(0.0, P.atkT - dt);
    shake *= .85;
    if (mpLowT > 0) mpLowT -= dt;
    if (atkHeld) attack();
    double mx = (_k(LogicalKeyboardKey.keyD, LogicalKeyboardKey.arrowRight) ? 1 : 0) -
        (_k(LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft) ? 1 : 0) + jx;
    double my = (_k(LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown) ? 1 : 0) -
        (_k(LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp) ? 1 : 0) + jy;
    var m = sqrt(mx * mx + my * my);
    if (m > 1) {
      mx /= m;
      my /= m;
      m = 1;
    }
    if (m < .12) {
      mx = my = 0;
      m = 0;
    }
    if (m > 0) {
      P.mdx = mx / m;
      P.mdy = my / m;
    }
    if (P.dashT > 0) {
      P.dashT -= dt;
      P.vx = P.mdx * 380;
      P.vy = P.mdy * 380;
      fx.add(Fx('d', x: P.x + rnd(-4, 4), y: P.y, t: .35));
    } else {
      final sp = P.atkT > 0 ? P.sp * .55 : P.sp, k = min(1.0, dt * 14);
      P.vx += (mx * sp - P.vx) * k;
      P.vy += (my * sp - P.vy) * k;
    }
    final spd = sqrt(P.vx * P.vx + P.vy * P.vy);
    P.moving = spd > 14;
    if (P.moving) {
      P.walk += dt * (7 + spd / 16);
      if (P.atkT <= 0 && (mx != 0 || my != 0)) {
        final ax = mx.abs(), ay = my.abs();
        if (ax > ay * 1.2) {
          P.dir = mx > 0 ? 'right' : 'left';
        } else if (ay > ax * 1.2) {
          P.dir = my > 0 ? 'down' : 'up';
        }
      }
      final nx = P.x + P.vx * dt, ny = P.y + P.vy * dt;
      if (!blocked(nx, P.y, 8)) {
        P.x = nx.clamp(20, WW - 20).toDouble();
      } else {
        P.vx = 0;
      }
      if (!blocked(P.x, ny, 8)) {
        P.y = ny.clamp(50, WH - 10).toDouble();
      } else {
        P.vy = 0;
      }
      if (rng.nextDouble() < dt * 9) fx.add(Fx('d', x: P.x + rnd(-5, 5), y: P.y, t: .35));
    } else {
      P.walk *= .8;
    }

    // healing orbs on the ground
    hoT -= dt;
    if (hoT <= 0) {
      hoT = stg == 1 ? 4 : 7;
      if (HO.length < 3) {
        final a = rnd(0, 6.28), r = rnd(60, 200);
        spawnH(P.x + cos(a) * r, P.y + sin(a) * r);
      }
    }
    for (final h in HO) {
      if (sqrt(pow(h.x - P.x, 2) + pow(h.y - (P.y - 10), 2)) < 26) {
        h.got = true;
        if (P.hp < 100) {
          P.hp = min(100.0, P.hp + (stg == 1 ? 18 : 14));
          fx.add(Fx('heal', t: .8));
          fx.add(Fx('dm', x: P.x, y: P.y - 100, v: '+HP', g: true, t: .9));
        }
        sfx('heal');
      }
    }
    HO.removeWhere((h) => h.got);

    waves(dt);
    if (state != 'play') return;
    for (final e in E) {
      final T = TY[e.t];
      e.fl -= dt;
      e.x += e.kx;
      e.y += e.ky;
      e.kx *= .8;
      e.ky *= .8;
      ai(e, T, dt);
      for (final o in E) {
        if (!identical(o, e)) {
          final ox = e.x - o.x, oy = e.y - o.y, od = sqrt(ox * ox + oy * oy);
          if (od > 0 && od < 30) {
            e.x += ox / od * .6;
            e.y += oy / od * .6;
          }
        }
      }
      final cy = e.y - T.h / 2, d = sqrt(pow(P.x - e.x, 2) + pow(P.y - 35 - cy, 2));
      if (d < 16 + T.h * .2 && P.inv <= 0) {
        P.hp -= e.dm;
        P.inv = 1;
        shake = 6;
        fx.add(Fx('hit', t: .3));
        vib(70);
        sfx('hurt');
      }
    }
    for (final p in PR) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.t -= dt;
      if (P.inv <= 0 && sqrt(pow(p.x - P.x, 2) + pow(p.y - (P.y - 35), 2)) < 15) {
        p.t = 0;
        P.hp -= 10;
        P.inv = .8;
        shake = 5;
        fx.add(Fx('hit', t: .3));
        vib(60);
      }
    }
    PR.removeWhere((p) => p.t <= 0);
    for (final o in O) {
      if (sqrt(pow(o.x - P.x, 2) + pow(o.y - (P.y - 20), 2)) < 28) {
        o.got = true;
        P.mp = min(100.0, P.mp + 30);
        P.hp = min(100.0, P.hp + 2);
        sfx('orb');
      }
    }
    O.removeWhere((o) => o.got);
    if (O.length < 4) spawnO();
    for (final f in fx) {
      f.t -= dt;
      if (f.k == 'p') {
        f.x += f.vx * dt;
        f.y += f.vy * dt;
      }
    }
    fx.removeWhere((f) => f.t <= 0);
    advT -= dt;
    final tx = G.en.where((s) => s.trim().isNotEmpty).toList();
    if (G.eo && P.hp < 35 && tx.isNotEmpty) {
      advShow = true;
      if (advT <= 0) {
        advT = 4;
        advText = tx[rng.nextInt(tx.length)];
      }
    } else {
      advShow = false;
    }
    if (P.hp <= 0) lose();
  }

  // ---------- end of stage
  void panel(String h, String p, bool nx) {
    state = 'over';
    atkHeld = false;
    advShow = false;
    G.write();
    panelH = h;
    panelP = p;
    panelNext = nx;
  }

  void lose() {
    if (state != 'play') return;
    panel('💀 خسرت', 'جرّب تاني — المرحلة $stg\nنصيحة: خد كرات الطاقة واستخدم الاندفاع 💨', false);
  }

  void win() {
    if (state != 'play') return;
    final r = P.hp / 100, st = r >= .7 ? 3 : (r >= .4 ? 2 : 1), first = G.sr[stg - 1] == 0;
    var g = 40 + 20 * stg;
    var tx = '';
    if (first) {
      g += S.rw.g;
      tx = S.rw.txt;
      if (S.rw.sw != null && !G.os.contains(S.rw.sw)) G.os.add(S.rw.sw!);
      if (S.rw.ch != null && !G.oc.contains(S.rw.ch)) G.oc.add(S.rw.ch!);
      if (S.rw.dash) G.dash = true;
    }
    if (st > G.sr[stg - 1]) G.sr[stg - 1] = st;
    if (stg < 7) G.u = max(G.u, stg + 1);
    G.gems += g;
    panel(stg == 7 ? '👑 خلّصت اللعبة!' : '🎉 المرحلة $stg خلصت!',
        '${'⭐' * st}\n💎 +$g${tx.isNotEmpty ? '\n🎁 $tx' : ''}', stg < 7);
  }
}
