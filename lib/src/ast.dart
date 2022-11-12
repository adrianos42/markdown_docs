// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Link resolver.
typedef Resolver = Node? Function(String name, [String? title]);

/// Base class for any AST item.
abstract class Node {
  ///
  void accept(NodeVisitor visitor);

  ///
  String get textContent => children.map((child) => child.textContent).join('');

  ///
  List<Node> get children => [];

  NodeVisitor? _visitor;

  ///
  void visitChildren() {
    for (final child in children) {
      child.accept(_visitor!);
    }

    _visitor = null;
  }
}

/// A plain [Text] element.
class Text extends Node {
  /// Creates a [Text] element.
  Text(this._text);

  final String _text;

  @override
  void accept(NodeVisitor visitor) => visitor.visitText(this);

  @override
  String get textContent => _text;
}

/// A [Paragraph] element.
class Paragraph extends Node {
  /// Creates a [Paragraph] element.
  Paragraph(this._children);

  final List<Node> _children;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitParagraph(this);
  }

  @override
  List<Node> get children => _children;
}

/// A [ListParagraph] element.
class ListParagraph extends Node {
  /// Creates a [ListParagraph] element.
  ListParagraph(this._children);

  final List<Node> _children;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitListParagraph(this);
  }

  @override
  List<Node> get children => _children;
}

/// A [Code] element.
class Code extends Node {
  /// Creates a [Code] element.
  Code(this._text);

  final String _text;

  @override
  void accept(NodeVisitor visitor) => visitor.visitCode(this);

  @override
  String get textContent => _text;
}

/// A [CodeBlock] element.
class CodeBlock extends Node {
  /// Creates a [CodeBlock] element.
  CodeBlock(this._text);

  final String _text;

  @override
  void accept(NodeVisitor visitor) => visitor.visitCodeBlock(this);

  @override
  String get textContent => _text;
}

/// A [FencedCodeBlock] element.
class FencedCodeBlock extends Node {
  /// Creates a [FencedCodeBlock] element.
  FencedCodeBlock(this._text, this._language);

  final String _text;

  final String? _language;

  @override
  void accept(NodeVisitor visitor) => visitor.visitFencedCodeBlock(this);

  @override
  String get textContent => _text;

  String? get language => _language;
}

/// The header level.
enum HeaderLevel {
  header1,
  header2,
  header3,
  header4,
  header5,
  header6,
}

/// A [Header] element.
class Header extends Node {
  /// Creates a [Header] element.
  Header(this._children, this._level);

  final List<Node> _children;

  final HeaderLevel _level;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitHeader(this);
  }

  HeaderLevel get level => _level;

  @override
  List<Node> get children => _children;
}

/// A [BlockQuote] element.
class BlockQuote extends Node {
  /// Creates a [BlockQuote] element.
  BlockQuote(this._children);

  final List<Node> _children;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitBlockQuote(this);
  }

  @override
  List<Node> get children => _children;
}

/// A [Table] element.
class Table extends Node {
  /// Creates a [Table] element.
  Table(this._children, {required this.columnCount});

  final List<Node> _children;

  final int columnCount;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitTable(this);
  }

  @override
  List<Node> get children => _children;
}

/// A [TableHeader] element.
class TableHeader extends Node {
  /// Creates a [TableHeader] element.
  TableHeader(this._children);

  final List<Node> _children;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitTableHeader(this);
  }

  @override
  List<Node> get children => _children;
}

/// A [TableRow] element.
class TableRow extends Node {
  /// Creates a [TableRow] element.
  TableRow(this._children);

  final List<Node> _children;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitTableRow(this);
  }

  @override
  List<Node> get children => _children;
}

enum TableCellAlignment {
  left,
  right,
  center,
}

/// A [TableCell] element.
class TableCell extends Node {
  /// Creates a [TableCell] element.
  TableCell(this._children, this.alignment, this.columnIndex);

  final List<Node> _children;

  final TableCellAlignment? alignment;

  final int columnIndex;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitTableCell(this);
  }

  @override
  List<Node> get children => _children;
}

/// A [HorizontalRule] element.
class HorizontalRule extends Node {
  /// Creates a [HorizontalRule] element.
  HorizontalRule();

  @override
  void accept(NodeVisitor visitor) {
    visitor.visitHorizontalRule(this);
  }

  @override
  String get textContent => '';
}

/// A [UnorderedListItem] element.
class UnorderedListItem extends Node {
  /// Creates a [UnorderedListItem] element.
  UnorderedListItem(this._children, this._checkbox);

  final List<Node> _children;
  final Checkbox? _checkbox;
  Checkbox? get checkbox => _checkbox;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitUnorderedListItem(this);
  }

  @override
  String get textContent => '';

  @override
  List<Node> get children => _children;
}

/// A [OrderedListItem] element.
class OrderedListItem extends Node {
  /// Creates a [OrderedListItem] element.
  OrderedListItem(this._children, this._checkbox);

  final List<Node> _children;
  final Checkbox? _checkbox;
  Checkbox? get checkbox => _checkbox;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitOrderedListItem(this);
  }

  @override
  String get textContent => '';

  @override
  List<Node> get children => _children;
}

/// A [OrderedList] element.
class OrderedList extends Node {
  /// Creates a [OrderedList] element.
  OrderedList(this._children, this._startNumber);

  final List<Node> _children;

  final int? _startNumber;

  /// The start number from the ordered list.
  int? get startNumber => _startNumber;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitOrderedList(this);
  }

  @override
  String get textContent => '';

  @override
  List<Node> get children => _children;
}

/// A [UnorderedList] element.
class UnorderedList extends Node {
  /// Creates a [UnorderedList] element.
  UnorderedList(this._children);

  final List<Node> _children;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitUnorderedList(this);
  }

  @override
  String get textContent => '';

  @override
  List<Node> get children => _children;
}

/// A [Checkbox] element.
class Checkbox {
  /// Creates a [Checkbox] element.
  Checkbox(this._checked);

  final bool _checked;

  bool get checked => _checked;
}

/// A [Link] element.
class Link extends Node {
  /// Creates a [Link] element.
  Link(this._text, this._url, this._children);

  final String? _text;

  final List<Node> _children;

  final String _url;
  String get url => _url;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitLink(this);
  }

  @override
  List<Node> get children => _children;
}

class Image extends Node {
  Image(this._destination, this._alternative, this._title);

  final String _destination;
  String get destination => _destination;

  final String _alternative;
  String get alternative => _alternative;

  final String? _title;
  String? get title => _title;

  @override
  void accept(NodeVisitor visitor) {
    visitor.visitImage(this);
  }

  @override
  String get textContent => _title ?? '';
}

/// A [Italic] text element.
class Italic extends Node {
  /// Creates a [Italic] element.
  Italic(this._children);

  final List<Node> _children;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitItalic(this);
  }

  @override
  List<Node> get children => _children;
}

/// A [Bold] text element.
class Bold extends Node {
  /// Creates a [Bold] element.
  Bold(this._children);

  final List<Node> _children;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitBold(this);
  }

  @override
  List<Node> get children => _children;
}

/// A [Strikethrough] text element.
class Strikethrough extends Node {
  /// Creates a [Strikethrough] element.
  Strikethrough(this._children);

  final List<Node> _children;

  @override
  void accept(NodeVisitor visitor) {
    _visitor = visitor;
    visitor.visitStrikethrough(this);
  }

  @override
  List<Node> get children => _children;
}

/// Inline content that has not been parsed into inline nodes (strong, links,
/// etc).
///
/// These placeholder nodes should only remain in place while the block nodes
/// of a document are still being parsed, in order to gather all reference link
/// definitions.
class UnparsedContent extends Node {
  /// Creates a [UnparsedContent] element.
  UnparsedContent(this._text);

  final String _text;

  @override
  String get textContent => _text;

  @override
  void accept(NodeVisitor visitor) {}
}

/// Visitor pattern for the AST.
///
/// Renderers or other AST transformers should implement this.
abstract class NodeVisitor {
  /// Called when a [Text] node has been reached.
  void visitText(Text text);

  /// Called when a [Code] node has been reached.
  void visitCode(Code code);

  /// Called when a [CodeBlock] node has been reached.
  void visitCodeBlock(CodeBlock codeBlock);

  /// Called when a [FencedCodeBlock] node has been reached.
  void visitFencedCodeBlock(FencedCodeBlock fencedCodeBlock);

  /// Called when a [Header] node has been reached.
  void visitHeader(Header header);

  /// Called when a [Paragraph] node has been reached.
  void visitParagraph(Paragraph paragraph);

  /// Called when a [ListParagraph] node has been reached.
  void visitListParagraph(ListParagraph listParagraph);

  /// Called when a [Link] node has been reached.
  void visitLink(Link link);

  /// Called when a [Strikethrough] node has been reached.
  void visitStrikethrough(Strikethrough strikethrough);

  /// Called when a [Bold] node has been reached.
  void visitBold(Bold bold);

  /// Called when a [Italic] node has been reached.
  void visitItalic(Italic italic);

  /// Called when a [HorizontalRule] node has been reached.
  void visitHorizontalRule(HorizontalRule horizontalRule);

  /// Called when a [BlockQuote] node has been reached.
  void visitBlockQuote(BlockQuote blockQuote);

  /// Called when a [UnorderedListItem] node has been reached.
  void visitUnorderedListItem(UnorderedListItem listElement);

  /// Called when a [OrderedListItem] node has been reached.
  void visitOrderedListItem(OrderedListItem listElement);

  /// Called when a [OrderedList] node has been reached.
  void visitOrderedList(OrderedList orderedList);

  /// Called when a [UnorderedList] node has been reached.
  void visitUnorderedList(UnorderedList unorderedList);

  /// Called when a [Image] node has been reached.
  void visitImage(Image image);

  /// Called when a [Table] node has been reached.
  void visitTable(Table table);

  /// Called when a [TableHeader] node has been reached.
  void visitTableHeader(TableHeader tableHeader);

  /// Called when a [TableRow] node has been reached.
  void visitTableRow(TableRow tableRow);

  /// Called when a [TableCell] node has been reached.
  void visitTableCell(TableCell tableCell);
}
