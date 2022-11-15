// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
import '../block_parser.dart';
import '../charcode.dart';
import '../patterns.dart';
import 'block_syntax.dart';

/// Parses tables.
class TableSyntax extends BlockSyntax {
  /// Creates a [TableSyntax].
  const TableSyntax();

  @override
  bool canEndBlock(BlockParser parser) => false;

  @override
  RegExp get pattern => dummyPattern;

  @override
  bool canParse(BlockParser parser) {
    // Note: matches *next* line, not the current one. We're looking for the
    // bar separating the head row from the body rows.
    return parser.matchesNext(tablePattern);
  }

  /// Parses a table into its three parts:
  ///
  /// * a head row of head cells
  /// * a divider of hyphens and pipes (not rendered)
  /// * many body rows of body cells
  @override
  Node? parse(BlockParser parser) {
    final alignments = _parseAlignments(parser.next!);
    final columnCount = alignments.length;
    final header = _parseRow(parser, alignments, false);

    if (header.children.length != columnCount) {
      return null;
    }

    // Advance past the divider of hyphens.
    parser.advance();

    final rows = <Node>[];

    while (!parser.isDone && !BlockSyntax.isAtBlockEnd(parser)) {
      final row = _parseRow(parser, alignments, true);
      final children = row.children;

      if (children.isNotEmpty) {
        while (children.length < columnCount) {
          children.add(TableCell(
            [Text('')],
            TableCellAlignment.left,
            children.length,
          ));
        }
        while (children.length > columnCount) {
          children.removeLast();
        }
      }

      while (row.children.length > columnCount) {
        row.children.removeLast();
      }

      rows.add(row);
    }

    if (rows.isEmpty) {
      return null;
    }

    return Table([header, ...rows], columnCount: columnCount);
  }

  List<TableCellAlignment?> _parseAlignments(String line) {
    final startIndex = _walkPastOpeningPipe(line);

    var endIndex = line.length - 1;
    while (endIndex > 0) {
      final ch = line.codeUnitAt(endIndex);
      if (ch == $pipe) {
        endIndex--;
        break;
      }
      if (ch != $space && ch != $tab) {
        break;
      }
      endIndex--;
    }

    // Optimization: We walk [line] too many times. One lap should do it.
    return line.substring(startIndex, endIndex + 1).split('|').map((column) {
      column = column.trim();
      if (column.startsWith(':') && column.endsWith(':')) {
        return TableCellAlignment.center;
      }
      if (column.startsWith(':')) {
        return TableCellAlignment.left;
      }
      if (column.endsWith(':')) {
        return TableCellAlignment.right;
      }
      return null;
    }).toList(growable: false);
  }

  /// Parses a table row at the current line into a table row element, with
  /// parsed table cells.
  ///
  /// [alignments] is used to annotate an alignment on each cell, and
  /// [cellType] is used to declare either "td" or "th" cells.
  Node _parseRow(
    BlockParser parser,
    List<TableCellAlignment?> alignments,
    bool isReallyARow,
  ) {
    final line = parser.current;
    final cells = <String>[];
    var index = _walkPastOpeningPipe(line);
    final cellBuffer = StringBuffer();

    while (true) {
      if (index >= line.length) {
        // This row ended without a trailing pipe, which is fine.
        cells.add(cellBuffer.toString().trimRight());
        cellBuffer.clear();
        break;
      }
      final ch = line.codeUnitAt(index);
      if (ch == $backslash) {
        if (index == line.length - 1) {
          // A table row ending in a backslash is not well-specified, but it
          // looks like GitHub just allows the character as part of the text of
          // the last cell.
          cellBuffer.writeCharCode(ch);
          cells.add(cellBuffer.toString().trimRight());
          cellBuffer.clear();
          break;
        }
        final escaped = line.codeUnitAt(index + 1);
        if (escaped == $pipe) {
          // GitHub Flavored Markdown has a strange bit here; the pipe is to be
          // escaped before any other inline processing. One consequence, for
          // example, is that "| `\|` |" should be parsed as a cell with a code
          // element with text "|", rather than "\|". Most parsers are not
          // compliant with this corner, but this is what is specified, and what
          // GitHub does in practice.
          cellBuffer.writeCharCode(escaped);
        } else {
          // The [InlineParser] will handle the escaping.
          cellBuffer.writeCharCode(ch);
          cellBuffer.writeCharCode(escaped);
        }
        index += 2;
      } else if (ch == $pipe) {
        cells.add(cellBuffer.toString().trimRight());
        cellBuffer.clear();
        // Walk forward past any whitespace which leads the next cell.
        index++;
        index = _walkPastWhitespace(line, index);
        if (index >= line.length) {
          // This row ended with a trailing pipe.
          break;
        }
      } else {
        cellBuffer.writeCharCode(ch);
        index++;
      }
    }

    parser.advance();

    final row = [
      for (int i = 0; i < cells.length; i += 1)
        TableCell([UnparsedContent(cells[i])], alignments[i], i)
    ];

    return isReallyARow ? TableRow(row) : TableHeader(row);
  }

  /// Walks past whitespace in [line] starting at [index].
  ///
  /// Returns the index of the first non-whitespace character.
  int _walkPastWhitespace(String line, int index) {
    while (index < line.length) {
      final ch = line.codeUnitAt(index);
      if (ch != $space && ch != $tab) {
        break;
      }
      index++;
    }
    return index;
  }

  /// Walks past the opening pipe (and any whitespace that surrounds it) in
  /// [line].
  ///
  /// Returns the index of the first non-whitespace character after the pipe.
  /// If no opening pipe is found, this just returns the index of the first
  /// non-whitespace character.
  int _walkPastOpeningPipe(String line) {
    var index = 0;
    while (index < line.length) {
      final ch = line.codeUnitAt(index);
      if (ch == $pipe) {
        index++;
        index = _walkPastWhitespace(line, index);
      }
      if (ch != $space && ch != $tab) {
        // No leading pipe.
        break;
      }
      index++;
    }
    return index;
  }
}
