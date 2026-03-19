// lib/features/game/widgets/crossword_grid_widget.dart
// Phase 4 — Core Game (tile-placement redesign)

import 'package:flutter/material.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';
import 'package:puzzle_game/features/game/widgets/grid_cell_widget.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';

// ---------------------------------------------------------------------------
// Grid cell data — computed from puzzle word slot positions
// ---------------------------------------------------------------------------

/// Precomputed data for a single (row, col) position in the crossword grid.
/// A position can belong to one slot (normal cell) or two slots (intersection).
class _GridCellData {
  final int row;
  final int col;
  final List<CellKey> cellKeys;

  _GridCellData({required this.row, required this.col})
      : cellKeys = [];

  bool get isIntersection => cellKeys.length > 1;
}

// ---------------------------------------------------------------------------
// CrosswordGridWidget
// ---------------------------------------------------------------------------

/// Renders the crossword grid computed from puzzle word slot positions.
/// Shows constraint chips above the grid and delegates cell interactions
/// to [GridCellWidget].
class CrosswordGridWidget extends StatelessWidget {
  final Puzzle puzzle;
  final List<PoolTile> tiles;
  final Map<int, SlotResult> slotResults;
  final void Function(PoolTile tile, CellKey target) onTileDropped;
  final void Function(int tileId) onTileReturned;
  final double cellSize;
  final double cellGap;

  const CrosswordGridWidget({
    super.key,
    required this.puzzle,
    required this.tiles,
    required this.slotResults,
    required this.onTileDropped,
    required this.onTileReturned,
    this.cellSize = 52,
    this.cellGap = 4,
  });

  /// Compute which (row, col) each cell of each word slot occupies.
  /// Intersection cells are detected when two slots share the same (row, col).
  Map<(int, int), _GridCellData> _computeGrid() {
    final grid = <(int, int), _GridCellData>{};

    for (final slot in puzzle.wordSlots) {
      final length = slot.requiredLength ?? 0;
      for (int pos = 0; pos < length; pos++) {
        final row = slot.isHorizontal ? slot.gridRow : slot.gridRow + pos;
        final col = slot.isHorizontal ? slot.gridCol + pos : slot.gridCol;
        final coord = (row, col);
        final cellKey = CellKey(slotId: slot.id, positionInSlot: pos);

        if (grid.containsKey(coord)) {
          grid[coord]!.cellKeys.add(cellKey);
        } else {
          final data = _GridCellData(row: row, col: col);
          data.cellKeys.add(cellKey);
          grid[coord] = data;
        }
      }
    }
    return grid;
  }

  PoolTile? _tileAt(CellKey cellKey) {
    for (final t in tiles) {
      if (t.placedAt == cellKey) return t;
    }
    return null;
  }

  /// For an intersection cell, use the result of the slot with the worst result.
  SlotResult _resultForCell(List<CellKey> cellKeys) {
    SlotResult worst = SlotResult.unvalidated;
    for (final ck in cellKeys) {
      final r = slotResults[ck.slotId] ?? SlotResult.unvalidated;
      if (r == SlotResult.wrongWord || r == SlotResult.wrongConstraint) return r;
      if (r == SlotResult.correct) worst = SlotResult.correct;
    }
    return worst;
  }

  @override
  Widget build(BuildContext context) {
    final grid = _computeGrid();
    if (grid.isEmpty) return const SizedBox.shrink();

    final allRows = grid.keys.map((k) => k.$1);
    final allCols = grid.keys.map((k) => k.$2);
    final minRow = allRows.reduce((a, b) => a < b ? a : b);
    final maxRow = allRows.reduce((a, b) => a > b ? a : b);
    final minCol = allCols.reduce((a, b) => a < b ? a : b);
    final maxCol = allCols.reduce((a, b) => a > b ? a : b);

    final rows = maxRow - minRow + 1;
    final cols = maxCol - minCol + 1;
    final step = cellSize + cellGap;

    // Build cell widgets positioned in the crossword grid
    final cellWidgets = <Widget>[];
    for (final entry in grid.entries) {
      final (r, c) = entry.key;
      final data = entry.value;
      final normRow = r - minRow;
      final normCol = c - minCol;

      // Primary key is first in the list; used for tile lookup and drop target.
      // For intersection cells, check all keys to find any placed tile.
      final primaryKey = data.cellKeys.first;
      PoolTile? foundTile = _tileAt(primaryKey);
      if (foundTile == null && data.cellKeys.length > 1) {
        foundTile = _tileAt(data.cellKeys[1]);
      }

      cellWidgets.add(Positioned(
        top: normRow * step,
        left: normCol * step,
        child: GridCellWidget(
          cellKey: primaryKey,
          placedTile: foundTile,
          isIntersection: data.isIntersection,
          slotResult: _resultForCell(data.cellKeys),
          onTileDropped: onTileDropped,
          onTileReturned: onTileReturned,
          size: cellSize,
        ),
      ));
    }

    final gridWidth = cols * step - cellGap;
    final gridHeight = rows * step - cellGap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Constraint chips for each word slot
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: puzzle.wordSlots.map((slot) {
            final isSolved = slotResults[slot.id] == SlotResult.correct;
            return _ConstraintChip(
              text: slot.constraint.displayText,
              isSolved: isSolved,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // The crossword grid itself
        Center(
          child: SizedBox(
            width: gridWidth,
            height: gridHeight,
            child: Stack(children: cellWidgets),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _ConstraintChip
// ---------------------------------------------------------------------------

class _ConstraintChip extends StatelessWidget {
  final String text;
  final bool isSolved;

  const _ConstraintChip({
    required this.text,
    required this.isSolved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSolved
            ? AppColors.verdigris.withValues(alpha: 0.18)
            : AppColors.aged,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: isSolved
              ? AppColors.verdigris.withValues(alpha: 0.5)
              : const Color(0x591C1410),
        ),
      ),
      child: Text(
        '\u2592 ${text.toUpperCase()}',
        style: TextStyle(
          fontFamily: 'SpecialElite',
          fontSize: 11,
          letterSpacing: 1.32,
          color: isSolved ? AppColors.verdigris : AppColors.ink,
        ),
      ),
    );
  }
}
