import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/core/engine/uci/uci_parser.dart';

void main() {
  group('parseInfo', () {
    test('parses a full centipawn line', () {
      final info = parseInfo(
        'info depth 18 seldepth 24 multipv 1 score cp 140 nodes 1200000 '
        'nps 1250000 hashfull 120 tbhits 0 time 960 pv e2e4 e7e5 g1f3',
      )!;

      expect(info.depth, 18);
      expect(info.seldepth, 24);
      expect(info.nodes, 1200000);
      expect(info.nps, 1250000);
      expect(info.time, const Duration(milliseconds: 960));
      final line = info.line!;
      expect(line.score, const CentipawnScore(140));
      expect((line.score as CentipawnScore).pawns, 1.40);
      expect(line.bound, ScoreBound.exact);
      expect(line.multiPv, 1);
      expect(line.pv, ['e2e4', 'e7e5', 'g1f3']);
      expect(line.firstMove, 'e2e4');
    });

    test('parses mate scores as mate, not centipawns', () {
      expect(
        parseInfo('info depth 12 score mate 4 pv d1h5')!.line!.score,
        const MateScore(4),
      );
      expect(
        parseInfo('info depth 12 score mate -3 pv g8f6')!.line!.score,
        const MateScore(-3),
      );
    });

    test('parses lower and upper bounds', () {
      expect(
        parseInfo('info depth 9 score cp 30 lowerbound nodes 10')!.line!.bound,
        ScoreBound.lowerBound,
      );
      expect(
        parseInfo('info depth 9 score cp 30 upperbound nodes 10')!.line!.bound,
        ScoreBound.upperBound,
      );
    });

    test('parses multipv rank', () {
      final line = parseInfo('info depth 8 multipv 3 score cp -12 pv b1c3')!
          .line!;
      expect(line.multiPv, 3);
      expect(line.score, const CentipawnScore(-12));
    });

    test('skips wdl values', () {
      final info = parseInfo(
        'info depth 10 score cp 20 wdl 100 850 50 nodes 5000 pv d2d4',
      )!;
      expect(info.nodes, 5000);
      expect(info.line!.firstMove, 'd2d4');
    });

    test('parses Xiangqi moves on rank 10', () {
      final line = parseInfo('info depth 10 score cp 5 pv h10g8 h1g3')!.line!;
      expect(line.pv, ['h10g8', 'h1g3']);
    });

    test('returns an info without a line when there is no score', () {
      final info = parseInfo('info depth 5 seldepth 7 nodes 300 nps 3000')!;
      expect(info.line, isNull);
      expect(info.nps, 3000);
    });

    test('ignores string, currmove and depthless lines', () {
      expect(parseInfo('info string classical evaluation enabled'), isNull);
      expect(parseInfo('info depth 5 currmove e2e4 currmovenumber 1'), isNull);
      expect(parseInfo('info nodes 100 nps 1000'), isNull);
    });

    test('ignores malformed lines without throwing', () {
      const malformed = [
        '',
        '   ',
        'info',
        'info depth',
        'info depth x',
        'info depth 5 score',
        'info depth 5 score cp',
        'info depth 5 score cp abc',
        'info depth 5 score banana 3',
        'bestmove e2e4',
        'id name Fairy-Stockfish',
        'readyok',
      ];
      for (final line in malformed) {
        expect(parseInfo(line), isNull, reason: line);
      }
    });
  });

  group('parseBestMove', () {
    test('parses a move with ponder', () {
      expect(
        parseBestMove('bestmove e2e4 ponder e7e5'),
        const EngineMove('e2e4', ponder: 'e7e5'),
      );
    });

    test('parses a move without ponder and with promotion', () {
      expect(parseBestMove('bestmove e7e8q'), const EngineMove('e7e8q'));
    });

    test('parses Xiangqi moves', () {
      expect(parseBestMove('bestmove h10g8'), const EngineMove('h10g8'));
    });

    test('represents "(none)" as no legal move', () {
      expect(parseBestMove('bestmove (none)'), const NoLegalMove());
    });

    test('rejects malformed lines', () {
      const malformed = [
        'bestmove',
        'bestmove xyz',
        'bestmove e2',
        'info depth 3',
        '',
      ];
      for (final line in malformed) {
        expect(parseBestMove(line), isNull, reason: line);
      }
    });
  });
}
