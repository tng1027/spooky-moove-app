/// Reference perft counts for the Xiangqi rules (OB-043).
///
/// Counts come from the bundled Fairy-Stockfish, produced by
/// `integration_test/xiangqi_perft_oracle_test.dart` on the iOS simulator
/// with:
///
/// ```
/// setoption name UCI_Variant value xiangqi
/// position fen <fen>
/// go perft <depth>
/// ```
library;

typedef XiangqiPerftPosition = ({String name, String fen, List<int> counts});

const List<XiangqiPerftPosition> xiangqiPerftPositions = [
  (
    name: 'start',
    fen:
        'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1',
    counts: [44, 1920, 79666, 3290240],
  ),
  (
    name: 'midgame',
    fen: 'rnbakabr1/9/9/p1p1n3p/6p2/2P6/Pc2P1PcP/1CN3N2/9/R1BAKABR1 w - - 0 7',
    counts: [29, 1271, 38825],
  ),
  (
    name: 'cannon screens',
    fen: '3k5/1r7/9/9/1p2c4/9/4P4/1C7/4R4/5K3 w - - 0 1',
    counts: [26, 632, 15754],
  ),
  (
    name: 'flying general',
    fen: '3k5/4a4/9/9/9/3R5/9/9/4N4/3K5 w - - 0 1',
    counts: [16, 33, 689],
  ),
  (
    name: 'horse legs and elephant eyes',
    fen: '2bakab2/9/2n1c1n2/2p6/9/2B1P4/3N5/4N4/9/3KA1B2 w - - 0 1',
    counts: [21, 502, 9053],
  ),
  (
    name: 'crossed soldiers',
    fen: 'P3k4/3P5/4P4/9/9/9/2r6/6p2/9/3K5 w - - 0 1',
    counts: [9, 128, 1002],
  ),
];
