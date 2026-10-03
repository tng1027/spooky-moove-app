import '../../../core/game/move_text.dart';
import 'xiangqi_models.dart';

/// Suggestion main line for Xiangqi (OB-046 REQ-004, XQ4): absolute points
/// in Red's frame, matching the board edge labels, never WXF.
abstract final class XiangqiMoveFormat {
  static const String captureMark = '✕';

  /// `H3 ➔ E3`, or `A1 ➔ A7 ✕` for a capture.
  static String moveLine(XiangqiMove move) {
    final line =
        '${move.from.name.toUpperCase()} ${MoveText.arrow} '
        '${move.to.name.toUpperCase()}';
    return move.isCapture ? '$line $captureMark' : line;
  }
}
