class ProfanityFilter {
  static const _blocked = <String>{
    'shit', 'fuck', 'cunt', 'cock', 'dick', 'ass', 'bitch', 'damn',
    'hell', 'piss', 'bastard', 'whore', 'slut', 'crap', 'fart',
    'arse', 'tits', 'boob', 'prick', 'wank', 'twat',
  };

  static bool isBlocked(String word) => _blocked.contains(word.toLowerCase());
}
