import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/board/intersection_board.dart';
import '../../../../core/board/smart_entry.dart';
import '../../../../core/board/tap_board.dart';
import '../../../../core/game/player_side.dart';
import '../../domain/xiangqi_models.dart';
import '../xiangqi_board_controller.dart';
import 'xiangqi_grid_painter.dart';
import 'xiangqi_piece_disc.dart';

/// Legal-only Xiangqi intersection tap board (OB-044), user's side at the
/// bottom. [size] comes from `AdvisorScreen.boardSizeFor(files: 9, ranks: 10)`.
class XiangqiBoard extends ConsumerWidget {
  const XiangqiBoard({required this.size, super.key = regionKey});

  static const Key regionKey = Key('advisor.board');

  final Size size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(xiangqiBoardControllerProvider);
    final controller = ref.read(xiangqiBoardControllerProvider.notifier);
    final entry = state.entry;
    final targets = state.targets;
    final suggestion = state.suggestedMove;

    BoardSquareState pointState(int file, int rank) {
      final point = XiangqiPoint(file, rank);
      return switch (entry) {
        SourceSelected(:final source) when source == point =>
          BoardSquareState.selected,
        DestinationSelected(:final destination) when destination == point =>
          BoardSquareState.selected,
        SourceSelected(:final destinations) when destinations.contains(point) =>
          BoardSquareState.candidate,
        DestinationSelected(:final sources) when sources.contains(point) =>
          BoardSquareState.candidate,
        _ when point == state.checkedGeneral => BoardSquareState.check,
        _ when !state.activePoints.contains(point) => BoardSquareState.dimmed,
        _ when point == suggestion?.from || point == suggestion?.to =>
          BoardSquareState.suggested,
        _ => BoardSquareState.normal,
      };
    }

    return SizedBox.fromSize(
      size: size,
      child: IntersectionBoard(
        files: XiangqiPoint.files,
        ranks: XiangqiPoint.ranks,
        flipped: state.userSide == PlayerSide.second,
        background: XiangqiGridPainter(cell: size.width / XiangqiPoint.files),
        pointState: pointState,
        isTarget: (file, rank) => targets.contains(XiangqiPoint(file, rank)),
        onTap: (file, rank) => controller.tap(XiangqiPoint(file, rank)),
        onMiss: controller.cancelEntry,
        fileLabel: (file) => String.fromCharCode('A'.codeUnitAt(0) + file),
        rankLabel: (rank) => '${rank + 1}',
        pieceBuilder: (file, rank) {
          final piece = state.pieces[XiangqiPoint(file, rank)];
          return piece == null ? null : XiangqiPieceDisc(piece);
        },
      ),
    );
  }
}
