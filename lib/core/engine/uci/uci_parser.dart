/// Pure parsing of UCI engine output.
library;

import '../engine_models.dart';

/// Parses an `info` line into a [SearchInfo].
///
/// Returns null for lines that carry no search progress (`info string`,
/// `currmove` updates, lines without a depth) and for malformed lines.
SearchInfo? parseInfo(String line) {
  final tokens = _tokenize(line);
  if (tokens.isEmpty || tokens.first != 'info') return null;

  int? depth;
  int? seldepth;
  int? multiPv;
  int? nodes;
  int? nps;
  int? timeMs;
  EngineScore? score;
  var bound = ScoreBound.exact;
  var pv = const <String>[];

  var i = 1;
  while (i < tokens.length) {
    final key = tokens[i++];
    switch (key) {
      case 'string':
      case 'currmove':
      case 'currmovenumber':
        return null;
      case 'pv':
        pv = List.unmodifiable(tokens.sublist(i));
        i = tokens.length;
      case 'score':
        if (i + 1 >= tokens.length) return null;
        final kind = tokens[i++];
        final value = int.tryParse(tokens[i++]);
        if (value == null) return null;
        score = switch (kind) {
          'cp' => CentipawnScore(value),
          'mate' => MateScore(value),
          _ => null,
        };
        if (score == null) return null;
        if (i < tokens.length && tokens[i] == 'lowerbound') {
          bound = ScoreBound.lowerBound;
          i++;
        } else if (i < tokens.length && tokens[i] == 'upperbound') {
          bound = ScoreBound.upperBound;
          i++;
        }
      case 'wdl':
        i += 3;
      case 'depth' ||
          'seldepth' ||
          'multipv' ||
          'nodes' ||
          'nps' ||
          'time' ||
          'hashfull' ||
          'tbhits':
        if (i >= tokens.length) return null;
        final value = int.tryParse(tokens[i++]);
        if (value == null) return null;
        switch (key) {
          case 'depth':
            depth = value;
          case 'seldepth':
            seldepth = value;
          case 'multipv':
            multiPv = value;
          case 'nodes':
            nodes = value;
          case 'nps':
            nps = value;
          case 'time':
            timeMs = value;
        }
      default:
        // Unknown keys are skipped with their value, if any.
        if (i < tokens.length && int.tryParse(tokens[i]) != null) i++;
    }
  }

  if (depth == null) return null;
  return SearchInfo(
    depth: depth,
    seldepth: seldepth,
    nodes: nodes,
    nps: nps,
    time: timeMs == null ? null : Duration(milliseconds: timeMs),
    line: score == null
        ? null
        : SearchLine(
            multiPv: multiPv ?? 1,
            depth: depth,
            score: score,
            bound: bound,
            pv: pv,
          ),
  );
}

/// Parses a `bestmove` line. Returns null if [line] is not a valid
/// `bestmove` line.
BestMove? parseBestMove(String line) {
  final tokens = _tokenize(line);
  if (tokens.length < 2 || tokens.first != 'bestmove') return null;

  final move = tokens[1];
  if (move == '(none)' || move == '0000') return const NoLegalMove();
  if (!_isMove(move)) return null;

  String? ponder;
  if (tokens.length >= 4 && tokens[2] == 'ponder' && _isMove(tokens[3])) {
    ponder = tokens[3];
  }
  return EngineMove(move, ponder: ponder);
}

List<String> _tokenize(String line) =>
    line.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

// Square = file letter + rank number (rank 10 for Xiangqi), optional
// promotion letter; drops such as `P@e4` for variants with drops.
final _movePattern = RegExp(r'^(?:[a-z]\d{1,2}|[A-Za-z]@)[a-z]\d{1,2}[a-z+]?$');

bool _isMove(String token) => _movePattern.hasMatch(token);
