import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../features/new_game/domain/game_kind.dart';
import '../../features/settings/domain/app_language.dart';
import '../game/player_side.dart';
import 'app_strings_en.dart';
import 'app_strings_vi.dart';

/// Every in-app UI string, visible and spoken, for one [AppLanguage]
/// (OB-053 R4). All fields are required, so a language missing a string
/// does not compile (BR-001).
///
/// Not here, and never translated (REQ-008): the app name, move
/// coordinates, the engine expert line, license texts and engine names.
/// Persona tier copy lives in `PersonaTierCopy`, the fair-play notice in
/// `FairPlayNoticeText`.
final class AppStrings {
  const AppStrings({
    required this.language,
    required this.close,
    required this.closeSpoken,
    required this.settingsTitle,
    required this.settingsTitleSpoken,
    required this.settingsEmpty,
    required this.settingsEmptySpoken,
    required this.languageTitle,
    required this.languageTitleSpoken,
    required this.aboutTitle,
    required this.aboutTitleSpoken,
    required this.aboutFreeSoftware,
    required this.aboutEngine,
    required this.aboutSourceHeading,
    required this.aboutReleaseTags,
    required this.aboutCopySource,
    required this.aboutCopySourceSpoken,
    required this.aboutCopied,
    required this.aboutCopiedSpoken,
    required this.aboutViewLicenses,
    required this.aboutViewLicensesSpoken,
    required this.aboutLegalese,
    required this.homeTitle,
    required this.homeTitleSpoken,
    required this.chessName,
    required this.chessNameSpoken,
    required this.chessTagline,
    required this.chessTaglineSpoken,
    required this.xiangqiName,
    required this.xiangqiNameSpoken,
    required this.xiangqiTagline,
    required this.xiangqiTaglineSpoken,
    required this.white,
    required this.whiteSpoken,
    required this.black,
    required this.blackSpoken,
    required this.red,
    required this.redSpoken,
    required this.back,
    required this.backSpoken,
    required this.fairPlay,
    required this.fairPlaySpoken,
    required this.newGameTitleSpokenPrefix,
    required this.playing,
    required this.yourSide,
    required this.yourSideSpoken,
    required this.firstMove,
    required this.firstMoveSpoken,
    required this.secondMove,
    required this.secondMoveSpoken,
    required this.startGame,
    required this.levelHelper,
    required this.newGame,
    required this.discardTitle,
    required this.discardTitleSpoken,
    required this.cancel,
    required this.gameOver,
    required this.waitingForOpponent,
    required this.pickLevelAbove,
    required this.confirmPlayed,
    required this.confirmPlayedSpoken,
    required this.undo,
    required this.pickLevel,
    required this.thinking,
    required this.bestMove,
    required this.engineError,
    required this.retry,
    required this.winRate,
    required this.youMateIn,
    required this.opponentMatesIn,
    required this.percentSpoken,
    required this.checkmate,
    required this.noMoves,
    required this.youWin,
    required this.youLose,
    required this.stalemateDraw,
    required this.drawInsufficientMaterial,
    required this.drawFivefold,
    required this.drawSeventyFiveMoves,
    required this.hintThreefold,
    required this.hintFiftyMoves,
  });

  static const AppStrings english = englishStrings;
  static const AppStrings vietnamese = vietnameseStrings;

  static AppStrings forLanguage(AppLanguage language) => switch (language) {
    AppLanguage.english => english,
    AppLanguage.vietnamese => vietnamese,
  };

  /// The strings of the app locale. English when no [delegate] is installed
  /// (widget tests that pump a bare `MaterialApp`); the app always installs it.
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ?? english;

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  final AppLanguage language;

  // Shared
  final String close;
  final String closeSpoken;

  // Settings, Language and About dialogs (OB-051, OB-033)
  final String settingsTitle;
  final String settingsTitleSpoken;
  final String settingsEmpty;
  final String settingsEmptySpoken;
  final String languageTitle;
  final String languageTitleSpoken;
  final String aboutTitle;
  final String aboutTitleSpoken;
  final String aboutFreeSoftware;
  final String aboutEngine;
  final String aboutSourceHeading;
  final String aboutReleaseTags;
  final String aboutCopySource;
  final String aboutCopySourceSpoken;
  final String aboutCopied;
  final String aboutCopiedSpoken;
  final String aboutViewLicenses;
  final String aboutViewLicensesSpoken;
  final String aboutLegalese;

  // Home (OB-049, OB-052 DS-9)
  final String homeTitle;
  final String homeTitleSpoken;
  final String chessName;
  final String chessNameSpoken;
  final String chessTagline;
  final String chessTaglineSpoken;
  final String xiangqiName;
  final String xiangqiNameSpoken;
  final String xiangqiTagline;
  final String xiangqiTaglineSpoken;

  // Sides (OB-042 REQ-001)
  final String white;
  final String whiteSpoken;
  final String black;
  final String blackSpoken;
  final String red;
  final String redSpoken;

  // New-game screen (OB-011, OB-052 DS-8)
  final String back;
  final String backSpoken;
  final String fairPlay;
  final String fairPlaySpoken;
  final String newGameTitleSpokenPrefix;
  final String playing;
  final String yourSide;
  final String yourSideSpoken;
  final String firstMove;
  final String firstMoveSpoken;
  final String secondMove;
  final String secondMoveSpoken;
  final String startGame;
  final String levelHelper;

  // Advisor screen (OB-007, OB-011, OB-012, OB-041)
  final String newGame;
  final String discardTitle;
  final String discardTitleSpoken;
  final String cancel;
  final String gameOver;
  final String waitingForOpponent;
  final String pickLevelAbove;
  final String confirmPlayed;
  final String confirmPlayedSpoken;
  final String undo;
  final String pickLevel;
  final String thinking;
  final String bestMove;
  final String engineError;
  final String retry;

  // Evaluation headline (OB-041, OB-052 DS-7)
  final String winRate;
  final String youMateIn;
  final String opponentMatesIn;
  final String percentSpoken;

  // Game results (OB-024, OB-047). Keep the ` — ` separator in two-part
  // texts: the card splits on it.
  final String checkmate;
  final String noMoves;
  final String youWin;
  final String youLose;
  final String stalemateDraw;
  final String drawInsufficientMaterial;
  final String drawFivefold;
  final String drawSeventyFiveMoves;
  final String hintThreefold;
  final String hintFiftyMoves;

  String gameName(GameKind game) => switch (game) {
    GameKind.chess => chessName,
    GameKind.xiangqi => xiangqiName,
  };

  String gameNameSpoken(GameKind game) => switch (game) {
    GameKind.chess => chessNameSpoken,
    GameKind.xiangqi => xiangqiNameSpoken,
  };

  String gameTagline(GameKind game) => switch (game) {
    GameKind.chess => chessTagline,
    GameKind.xiangqi => xiangqiTagline,
  };

  String gameTaglineSpoken(GameKind game) => switch (game) {
    GameKind.chess => chessTaglineSpoken,
    GameKind.xiangqi => xiangqiTaglineSpoken,
  };

  /// The user-visible name of [side] in [game] (OB-042 REQ-001).
  String sideName(GameKind game, PlayerSide side) => switch ((game, side)) {
    (GameKind.chess, PlayerSide.first) => white,
    (GameKind.xiangqi, PlayerSide.first) => red,
    (_, PlayerSide.second) => black,
  };

  String sideNameSpoken(GameKind game, PlayerSide side) =>
      switch ((game, side)) {
        (GameKind.chess, PlayerSide.first) => whiteSpoken,
        (GameKind.xiangqi, PlayerSide.first) => redSpoken,
        (_, PlayerSide.second) => blackSpoken,
      };

  String moveOrder(PlayerSide side) => switch (side) {
    PlayerSide.first => firstMove,
    PlayerSide.second => secondMove,
  };

  String moveOrderSpoken(PlayerSide side) => switch (side) {
    PlayerSide.first => firstMoveSpoken,
    PlayerSide.second => secondMoveSpoken,
  };
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLanguage.fromCode(locale.languageCode) != null;

  @override
  Future<AppStrings> load(Locale locale) => SynchronousFuture(
    AppStrings.forLanguage(AppLanguage.fromDeviceCode(locale.languageCode)),
  );

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
