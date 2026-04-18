import 'package:flutter/painting.dart';

import '../models/tile.dart';

Color colorFor(Tile t) {
  return switch (t) {
    Tile.a => const Color(0xFFE53935),
    Tile.b => const Color(0xFF2E7D32),
    Tile.c => const Color(0xFF1E88E5),
    Tile.d => const Color(0xFFF9A825),
    Tile.e => const Color(0xFF8E24AA),
    _ => const Color(0xFF1E1E1E),
  };
}
