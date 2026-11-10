class LevelHelper {
  // Level 1 to 99 progression curve
  // Level 1 requires 0 EXP
  // Higher levels require exponentially more EXP
  static int getExpRequiredForLevel(int level) {
    if (level <= 1) return 0;
    if (level > 99) level = 99;
    return (100 * (level * level * 0.55)).round();
  }

  // Calculates level from 1 to 99 based on total accumulated EXP
  static int calculateLevel(int totalExp) {
    if (totalExp <= 0) return 1;
    for (int lvl = 99; lvl >= 1; lvl--) {
      if (totalExp >= getExpRequiredForLevel(lvl)) {
        return lvl;
      }
    }
    return 1;
  }

  // Returns current progress percentage and required EXP for the next level
  static Map<String, dynamic> getLevelProgress(int totalExp) {
    int currentLvl = calculateLevel(totalExp);
    if (currentLvl >= 99) {
      return {
        'level': 99,
        'currentExp': totalExp,
        'neededExp': totalExp,
        'progress': 1.0,
        'totalExp': totalExp,
      };
    }

    int currentLvlBaseExp = getExpRequiredForLevel(currentLvl);
    int nextLvlTargetExp = getExpRequiredForLevel(currentLvl + 1);

    int expInCurrentLvl = totalExp - currentLvlBaseExp;
    int expDifference = nextLvlTargetExp - currentLvlBaseExp;

    double progress = expDifference > 0
        ? (expInCurrentLvl / expDifference).clamp(0.0, 1.0)
        : 0.0;

    return {
      'level': currentLvl,
      'currentExp': expInCurrentLvl,
      'neededExp': expDifference,
      'progress': progress,
      'totalExp': totalExp,
    };
  }
}
