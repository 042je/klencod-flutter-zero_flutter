import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class CharImgs {
  late ui.Image down, up, side;
  List<ui.Image>? walk, sw, bk;
  double wh = 1, whs = 1, whb = 1;
}

class Assets {
  final Map<String, CharImgs> chars = {};
  final List<ui.Image?> mons = List.filled(5, null);
  final List<ui.Image> swords = [];
  late ui.Image map;

  static Future<ui.Image> _load(String f) async {
    final data = await rootBundle.load('assets/img/$f');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  static Future<List<ui.Image>> _list(String base, int n) async =>
      [for (var i = 0; i < n; i++) await _load('${base}_$i.webp')];

  static Future<Assets> loadAll() async {
    final a = Assets();
    for (final k in ['purple', 'pink', 'black', 'hijab']) {
      final c = CharImgs()
        ..down = await _load('${k}_down.webp')
        ..up = await _load('${k}_up.webp')
        ..side = await _load('${k}_side.webp');
      if (k == 'hijab') {
        c.walk = await _list('hijab_walk', 4);
        c.sw = await _list('hijab_sw', 2);
        c.bk = await _list('hijab_bk', 2);
        c.wh = c.whs = c.whb = 1.0025;
      }
      a.chars[k] = c;
    }
    for (var i = 1; i < 5; i++) a.mons[i] = await _load('mons_$i.webp');
    for (var i = 0; i < 4; i++) a.swords.add(await _load('swords_$i.webp'));
    a.map = await _load('map.jpg');
    return a;
  }
}
