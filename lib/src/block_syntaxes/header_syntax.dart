// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
import '../block_parser.dart';
import '../patterns.dart';
import 'block_syntax.dart';

/// Parses atx-style headers: `## Header ##`.
class HeaderSyntax extends BlockSyntax {
  const HeaderSyntax();

  @override
  RegExp get pattern => headerPattern;

  @override
  Node parse(BlockParser parser) {
    final match = pattern.firstMatch(parser.current)!;
    parser.advance();
    final level = match[1]!.length;
    final contents = UnparsedContent(match[2]!.trim());

    if (level >= 1 && level <= 6) {
      return Header([contents], HeaderLevel.values[level - 1]);
    }

    throw 'Invalid header level';
  }
}
