/// Fixed Xiangqi positions for the OB-010 performance pass.
///
/// Engineering-proposed set (OB-010 Open Question 2), Fairy-Stockfish FEN
/// with Red (upper case) at the bottom. Covers the opening, a developed
/// middlegame with many legal moves (worst case for the all-move tiers),
/// tactics, endgames, a forced mate and a position in check.
library;

typedef XiangqiBenchPosition = ({String name, String fen});

const List<XiangqiBenchPosition> xiangqiBenchPositions = [
  (
    name: 'start',
    fen:
        'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1',
  ),
  (
    name: 'central cannon',
    fen: 'rnbakab1r/9/1c4nc1/p1p1p1p1p/9/9/P1P1P1P1P/1C2C4/9/RNBAKABNR w - - 2 2',
  ),
  (
    name: 'developed, rooks out',
    fen: 'r1bakab1r/9/1cn3nc1/p1p1p1p1p/9/9/P1P1P1P1P/1CN3NC1/R7R/2BAKAB2 w - - 6 4',
  ),
  (
    name: 'midgame',
    fen: 'rnbakabr1/9/9/p1p1n3p/6p2/2P6/Pc2P1PcP/1CN3N2/9/R1BAKABR1 w - - 0 7',
  ),
  (
    name: 'cannon screens',
    fen: '3k5/1r7/9/9/1p2c4/9/4P4/1C7/4R4/5K3 w - - 0 1',
  ),
  (
    name: 'horse and elephant endgame',
    fen: '2bakab2/9/2n1c1n2/2p6/9/2B1P4/3N5/4N4/9/3KA1B2 w - - 0 1',
  ),
  (name: 'crossed soldiers', fen: 'P3k4/3P5/4P4/9/9/9/2r6/6p2/9/3K5 w - - 0 1'),
  (name: 'mate in one', fen: '3k5/R8/8r/9/9/9/9/9/1R7/4K4 w - - 0 1'),
  (name: 'in check', fen: '4k4/9/9/4r4/9/9/9/R1N6/9/3AK4 w - - 0 1'),
];
