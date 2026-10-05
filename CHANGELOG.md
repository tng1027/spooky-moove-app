# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow `x.y.z+build` from `pubspec.yaml`.

## [1.0.0+2] - 2026-10-05

### Added
- Vietnamese app language: TIẾNG VIỆT in the Language dialog, all screens and screen-reader labels translated, device language by default, saved choice wins; the fair-play notice follows the app language.
- Level card on the new-game screen: icon, name, strength bar and a short description of the selected level.

### Changed
- The seven levels are renamed (Noob … Big brain / Gà mờ … Cao thủ) and each has its own icon; level keys during a game show the icon only.

## [1.0.0+1] - 2026-10-05

First release.

### Added
- Chess support with full rules: castling, en passant, promotion with a picture picker, and game-end detection (checkmate, stalemate, automatic draws, claimable-draw hint).
- Xiangqi (Chinese Chess) support on a traditional board with Chinese-character pieces, tap snapping, and game-end detection (checkmate, no legal moves).
- Home screen game picker and quick new-game setup (side and level, with defaults).
- On-device, offline move suggestions with win chance, mate-in-N, green board highlight, plain "from ➔ to" instructions, and an expert details line.
- Seven suggestion levels (Baby, Gentle, Soft, Even, Solid, Master, God), switchable mid-game.
- Two-tap legal-only move entry, one-tap "I played it", unlimited undo, Retry for slow suggestions, and haptic feedback.
- Turn guidance and a confirmation prompt before discarding a game in progress.
- One-time fair-play notice (English and Vietnamese), viewable again any time.
- Home header Settings and Language dialogs (English only).
- Dark, high-contrast design with game-style home and new-game screens and per-game accent colors.
- No account, ads, analytics, or data collection.
