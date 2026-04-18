/// Central place for score math — must stay in sync with [CandyFlameGame] clear waves.
class MatchScoring {
  MatchScoring._();

  /// Points per removed tile before rush / cascade multiplier.
  static const int kScorePerTile = 20;

  /// One scoring wave: `tilesRemoved * kScorePerTile * rush`.
  static int scoreDeltaForClear({
    required int tilesRemoved,
    required int rush,
  }) {
    if (tilesRemoved <= 0 || rush <= 0) {
      return 0;
    }
    return tilesRemoved * kScorePerTile * rush;
  }
}
