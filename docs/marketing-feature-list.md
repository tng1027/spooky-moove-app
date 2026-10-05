# SpookyMoove — Feature List for Marketing

Prepared: 5 October 2026. Source: product documents, backlog tickets and the current app build.

> **Read this first.** The app has **not been released yet**. Everything marked **Available** is built and tested on an iPhone simulator; testing on real iPhones and on Android phones is still to come. Before you publish anything, check the "Do not overclaim" section and get final copy approved by the Product Owner (the store listing review is still open).

---

## 1. Product overview

**What it is.** SpookyMoove is a training companion for people who play **Chess** and **Xiangqi (Chinese Chess)** on a **real, physical board**. You copy each move onto a simple board on your phone with two taps. When it's your turn, the app suggests a move and shows how good your position is.

**Who it's for.**
- **Parents and families** who want to play balanced, fun games with a child, including parents who don't know chess notation.
- **Club and casual players** who want instant feedback during friendly games over the board.
- **Players of both Western and Chinese chess** who want one app for both.
- **Players who want quick hints** without menus, animations or ads getting in the way.

**Core value proposition.** One small, private, offline app that sits next to your real board. You choose a "personality" for the suggestions, from deliberately gentle (great for playing with kids) up to full strength (great for studying). Entering a move takes two taps, and the app works with no internet.

---

## 2. Features by area

Status: **Available** = built in the current app. **In progress** = being worked on now. **Planned** = on the roadmap, not started. Only advertise **Available** features.

### 2.1 Games

| Feature | What it does | Why users care | Status |
|---|---|---|---|
| Chess | Full chess support, including castling, en passant and pawn promotion. | Play standard chess on your own board with the app as a coach. | Available |
| Xiangqi (Chinese Chess) | Full Xiangqi support on a traditional board with the river and palace, with pieces shown as Chinese characters. | Authentic Chinese chess, not a reskinned Western board. | Available |
| Two games in one app | Pick Chess or Xiangqi from the home screen. | No need to install a separate app for each game. | Available |

### 2.2 Move suggestions

| Feature | What it does | Why users care | Status |
|---|---|---|---|
| Suggested move on your turn | When it's your turn, the app shows its suggested move in large, easy-to-read text. | You get a clear answer at a glance, without staring at your phone. | Available |
| Move highlighted on the board | The suggested move is also highlighted in green on the on-screen board. | You can see right away which piece to move and where. | Available |
| Plain-language move instructions | Moves are shown as "from square to square" (for example E2 ➔ E4). Special moves get extra lines, such as "also move the rook" when castling, or a picture of the piece when promoting. | No chess notation needed. | Available |
| Win chance | Shows your chance of winning as a percentage, or "you mate in N" / "opponent mates in N". | You can tell at a glance how the game is going. | Available |
| Expert details line | A small extra line for experienced players with the engine's score and search depth. Xiangqi also shows the traditional move notation here. | Advanced players get the detail; beginners can ignore it. | Available |
| Fast suggestions | Suggestions are designed to appear within about one second. | Doesn't slow down your real game. | Available (to be confirmed on real phones) |
| "I played it" button | If you played the suggested move, one tap records it. If you played something else, just enter it on the board. | Your own move takes one tap, and you're always free to play your own way. | Available |
| Retry when slow | If a suggestion takes too long, a Retry button appears. | You're never stuck. | Available |

### 2.3 Suggestion personalities (7 levels)

The same 7 levels work in both games. They change **only the move the app suggests to you**. The app never plays against you.

| Level | What it suggests | Best for | Status |
|---|---|---|---|
| 🥚 Baby | Deliberately the weakest moves. | Letting a young child win. | Available |
| 🐣 Gentle | Clearly weaker moves. | Relaxed games with beginners. | Available |
| 🐥 Soft | Slightly weaker moves. | Light handicap against a weaker player. | Available |
| 🥉 Even (default) | Moves that keep the game close to 50/50, and the best move when you're behind. | Balanced, exciting games for everyone. | Available |
| 🥈 Solid | The best move, with moderate calculation. | Strong play and practice. | Available |
| 🥇 Master | The best move, with deeper calculation. | Serious study. | Available |
| 👑 God | Full-strength best move. | Maximum strength analysis. | Available (**name may change**, see section 5) |

| Feature | What it does | Why users care | Status |
|---|---|---|---|
| Change level any time | Switch level in the middle of a game and the suggestion updates right away. | Adjust the challenge as the game unfolds. | Available |

### 2.4 Entering moves

| Feature | What it does | Why users care | Status |
|---|---|---|---|
| Two-tap move entry | Tap a piece to see where it can go, then tap where it went. | Fast, and you can keep your eyes on the real board. | Available |
| Only legal moves allowed | Illegal moves can't be entered, and squares you can't use are dimmed. | Fewer mistakes, and a built-in check that the phone matches your real board. | Available |
| Easy promotion | When a pawn promotes, you pick the new piece from pictures. | No notation needed. | Available |
| Forgiving taps on the Xiangqi board | A tap slightly off target snaps to the nearest valid point. | Comfortable on smaller phones. | Available |
| Undo | Each tap takes back one move, as far back as you like, even after the game has ended. | Fix entry mistakes or replay a moment. | Available |
| Vibration feedback | The phone vibrates gently on taps, when a suggestion is ready, and more strongly when you're in check. | Confirms each action without you looking at the screen. | Available |

### 2.5 Game flow

| Feature | What it does | Why users care | Status |
|---|---|---|---|
| Home screen game picker | Choose Chess or Xiangqi from a simple list. | Start in seconds. | Available |
| Quick new-game setup | Pick your side (White/Black or Red/Black) and a level. Sensible defaults are already selected. | One tap on START GAME and you're playing. | Available |
| Turn guidance | The screen always shows whose move it is and what to do next. | You never lose track of the game. | Available |
| Game-end detection | Chess: checkmate, stalemate and automatic draws, plus a plain-language hint when a draw can be claimed. Xiangqi: checkmate and "no moves" (a loss under Xiangqi rules). The board locks and offers a new game. | Clear results with no arguments over the rules. | Available |
| New game safety prompt | The app asks before throwing away a game in progress. | No accidental resets. | Available |

### 2.6 Fair play and trust

| Feature | What it does | Why users care | Status |
|---|---|---|---|
| Fair-play notice | On first launch, a one-time notice explains that the app is for training and friendly play, not rated or tournament games. You can view it again at any time. | Positions the app as an honest training tool. | Available (wording pending legal review) |
| Bilingual notice | The fair-play notice is shown in English or Vietnamese, depending on the phone's language. | Local-language clarity for Vietnamese users. | Available |
| Private by design | No account, no ads, no analytics or tracking. The app collects no personal data. | Peace of mind for families. | Available |
| Works offline | All analysis runs on the phone, with no server needed. | Use it anywhere: at home, in a park, on a plane. | Available |

### 2.7 Look and feel

| Feature | What it does | Why users care | Status |
|---|---|---|---|
| Dark, high-contrast design | A calm dark theme with large type and clear buttons. | Easy to read at a glance, and easy on the eyes. | Available |
| Playful game-style screens | Chunky, game-like home and setup screens, with a signature color for each game (pink for Chess, blue for Xiangqi). The boards themselves stay clean and flat. | Feels fun and friendly, not like a spreadsheet. | In progress (built, final review pending) |
| No distracting animations | The boards are simple and static. | Keeps the focus on the real game. | Available |
| Accessibility basics | Screen-reader labels and support for large system text sizes. | Usable by more people. | Available (not formally audited) |

### 2.8 Settings and language

| Feature | What it does | Why users care | Status |
|---|---|---|---|
| Language picker | A language button on the home screen. Only English is offered today. | Groundwork for more languages. | Available (English only) |
| Settings | A settings button on the home screen. It has no options yet. | — | Placeholder; **do not advertise** |
| About and open-source licenses screen | Credits and licenses for the open-source parts. | Transparency. | Planned |

---

## 3. Key differentiators

1. **Made for real boards.** Most chess apps want you to play on the screen. SpookyMoove supports the game in front of you.
2. **Personalities from Baby to full strength.** The same app can help a parent lose gracefully to a child, or help a student study seriously.
3. **"Even" mode keeps games close.** Suggestions aim for a balanced, exciting game rather than a crushing win.
4. **No notation needed.** Pictures, coordinates and "from ➔ to" moves only.
5. **Two-tap entry and one-tap "I played it".** Built for speed, so you can keep your eyes on the board.
6. **Chess and Chinese Chess in one app,** each with its own authentic board and pieces.
7. **Offline and private.** No account, no ads, no tracking, no internet required.
8. **Small download.** The latest internal measurement is about 10 MB compressed (to be confirmed on the store build).

---

## 4. Suggested taglines and blurbs

Taglines (avoid the banned words listed in section 5):
- "Your coach for the real board."
- "Play together. Learn together."
- "From Baby steps to master moves."
- "Fair games for every family."
- "Chess and Chinese Chess, right beside your board."

Short blurbs:
- **Family:** "Playing chess with your kids? Set SpookyMoove to Baby or Gentle and keep every game fun and close, even if you've never read chess notation."
- **Students:** "Copy your over-the-board game in two taps and see your win chance after every move. Switch to Master when you want a serious second opinion."
- **Privacy:** "No account. No ads. No tracking. No internet needed. Just you, your board and a smart training companion."
- **Two games:** "One app for Chess and Xiangqi, each with its own authentic board, pieces and rules."

---

## 5. Platforms, limitations and "do not overclaim"

**Platforms**
- **iPhone (iOS 15 or later)** and **Android phones (Android 7.0 or later)** are the targets.
- So far, testing has been done **only on an iPhone simulator**. Real iPhone and all Android testing are still pending. Don't announce launch dates or "available on Google Play/App Store" until release is confirmed.
- iPad and tablets have not been tested or validated. Don't advertise tablet support.

**Do not claim**
- **More games.** Shogi, Go, Othello and Gomoku/Caro are **not** in the app. Don't say "all your favorite board games" or name these games.
- **Languages.** The app is **English only**. Only the fair-play notice is also in Vietnamese. Don't advertise a Vietnamese app or other languages.
- **Game history or saving.** The app does **not** save past games, and it does **not** resume a game after the app is closed. It always reopens at the home screen.
- **Settings or customization.** There are no settings yet, and only a dark theme.
- **Online features.** There is no online play, no opponents, no cloud sync and no account.
- **Custom positions.** Games always start from the standard starting position.
- **Speed and size.** "About one second" and "about 10 MB" are internal targets and measurements, not yet confirmed on real phones. Use soft wording such as "fast" and "lightweight".
- **Strength.** Don't use "Grandmaster-level", "unbeatable" or ratings without Product Owner sign-off.
- **Xiangqi rule details.** Perpetual check/chase rules and automatic draws are not applied in Xiangqi.
- **Free or Pro.** Everything is currently free with no purchases. A paid tier may come later, so don't promise "free forever".

**Banned words** (store compliance, required by the product team): never use **cheat, hack, stealth, bot, auto-move, undetected** or similar words, and never describe the app as a "real-time advisor/assistant". The approved positioning is **"Family Companion & Training Assistant"**. Also avoid "GOD MODE": the name of the top level (👑 God) is still under review and may change before launch.

**Fair-play message.** Every campaign should be consistent with the in-app notice: the app is for **training, casual study, handicap games and friendly offline play**, and must not be used in rated or tournament games without the arbiter's permission.

---

## 6. Coming soon / In progress (do not advertise yet)

| Item | Status | Note |
|---|---|---|
| Playful game-style restyle of home and setup screens | In progress | Built; awaiting final review and performance check. |
| Real-device testing (iPhone and Android) and performance checks | In progress | Required before release. |
| Store listing, final naming of the top level, legal review | In progress | Needed before submission. |
| About / open-source licenses screen | Planned | Will live in Settings. |
| Settings content | Planned | Content not yet decided. |
| More languages | Planned | Not scheduled. |
| Downloadable game packs (keeps the base app small) | Planned | Needed before the games below. |
| Shogi (Japanese Chess) | Planned | After game packs. |
| Gomoku / Caro | Planned | Rules and board size still undecided. |
| Othello / Reversi | Planned | — |
| Go / Weiqi | Planned | Board size and rules still undecided. |
| Game history | Planned | Requirements not yet defined. |
| Premium ("Pro") option | Deferred | Paused by the Product Owner; no purchases in the first release. |

---

## Appendix — Feature-to-ticket mapping

| Feature | Tickets |
|---|---|
| Chess rules, tap board, promotion | OB-006, OB-048 |
| Chess game end | OB-024 |
| Xiangqi rules, board, game end | OB-009 (epic), OB-043, OB-044, OB-047 |
| Xiangqi in new game / advisor | OB-045, OB-046 |
| Suggestion card, win chance, highlight, vibration, Retry | OB-007 |
| 7 personality levels | OB-021, OB-022, OB-023 |
| Turn guidance and "I played it" | OB-025, OB-041 |
| Undo | OB-012 |
| New game flow, home picker, headers | OB-011, OB-049, OB-050 |
| Fair-play notice (EN/VI) | OB-008 |
| Settings and language picker | OB-051 |
| Game-style restyle and game colors | OB-052 |
| Offline engine | OB-004, OB-005 |
| Size and speed checks | OB-010 |
| About / licenses screen | OB-033 |
| Store positioning, banned words, top-level naming | OB-034 |
| Audience, privacy, no data collected | OB-040, OB-035 |
| Downloadable packs | OB-014, OB-015 |
| Shogi / Gomoku-Caro / Othello / Go | OB-016, OB-026 / OB-017, OB-027, OB-028 / OB-018, OB-029 / OB-019, OB-020, OB-030, OB-031 |
| Game history | OB-013 |
| Monetization (deferred) | OB-035–OB-039 |
| Licensing (release blocker) | OB-002, OB-032 |
