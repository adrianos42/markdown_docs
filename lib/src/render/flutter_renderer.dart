// Copyright (c) 2022, Adriano Souza. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math' as math;

import '../ast.dart';
import '../block_syntaxes/block_syntax.dart';
import '../document.dart';
import '../extension_set.dart';
import '../inline_syntaxes/inline_syntax.dart';
import 'code_languages/dart_code.dart';

const _kFontFamily = 'IBM Plex Sans';
const _kFontPackage = 'desktop';
const _kDefaultItemPadding = 16.0;
const _kDefaultBlockBackgroundIndex = 4;
const _kDefaultQuoteBlockNestedBackgroundIndex = 0;

/// Converts the given string of Markdown to Flutter code.
String markdownToFlutter(
  String markdown, {
  Iterable<BlockSyntax> blockSyntaxes = const [],
  Iterable<InlineSyntax> inlineSyntaxes = const [],
  ExtensionSet? extensionSet,
  Resolver? linkResolver,
  Resolver? imageLinkResolver,
  bool inlineOnly = false,
  bool withDefaultBlockSyntaxes = true,
  bool withDefaultInlineSyntaxes = true,
}) {
  final document = Document(
    blockSyntaxes: blockSyntaxes,
    inlineSyntaxes: inlineSyntaxes,
    extensionSet: extensionSet,
    linkResolver: linkResolver,
    imageLinkResolver: imageLinkResolver,
    withDefaultBlockSyntaxes: withDefaultBlockSyntaxes,
    withDefaultInlineSyntaxes: withDefaultInlineSyntaxes,
  );

  if (inlineOnly) {
    return renderToFlutter(document.parseInline(markdown));
  }

  // Replace windows line endings with unix line endings, and split.
  final lines = markdown.replaceAll('\r\n', '\n').split('\n');

  final nodes = document.parseLines(lines);

  return '${renderToFlutter(nodes)}\n';
}

/// Renders [nodes] to Flutter.
String renderToFlutter(List<Node> nodes) => FlutterRenderer().render(nodes);

/// Translates a parsed AST to Flutter.
class FlutterRenderer implements NodeVisitor {
  /// Creates a [FlutterRenderer] element.
  FlutterRenderer();

  final StringBuffer _buffer = StringBuffer();
  final List<String> _lastTextStyle = ['textTheme.body1'];

  HeaderLevel? _previousHeader;
  bool _isFirstHeader = false;

  final List<bool> _hasOpenSpan = [false];

  /// Renders the parsed AST.
  String render(List<Node> nodes) {
    for (final node in nodes) {
      node.accept(this);
    }

    return '''
      Column(
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [$_buffer],
      )
    ''';
  }

  @override
  void visitText(Text text) {
    // Weird spec from markdown.
    final textContent = text.textContent.replaceAll('\n', ' ');

    if (_hasOpenSpan.last) {
      _buffer.write('''
        const TextSpan(text: r\'\'\'$textContent\'\'\'),
      ''');
    } else {
      _buffer.write('''
        const Text(r\'\'\'$textContent\'\'\'),
      ''');
    }
  }

  @override
  void visitParagraph(Paragraph paragraph) {
    if (_hasOpenSpan.last) {
      throw 'Invalid state: `Paragraph`';
    }

    String widget = '''Text.rich(TextSpan(children: [''';

    widget = '''
      Padding(
        padding: const EdgeInsets.only(bottom: $_kDefaultItemPadding), 
        child: $widget
    ''';

    _buffer.write(widget);

    _hasOpenSpan.add(true);

    paragraph.visitChildren();

    _buffer.write('],),),),');

    _hasOpenSpan.removeLast();
    _previousHeader = null;
  }

  @override
  void visitListParagraph(ListParagraph paragraph) {
    if (_hasOpenSpan.last) {
      throw 'Invalid state: `ListParagraph`';
    }

    String widget = '''Text.rich(TextSpan(children: [''';

    widget = '''
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0), 
        child: $widget
    ''';

    _buffer.write(widget);

    _hasOpenSpan.add(true);

    paragraph.visitChildren();

    _buffer.write('],),),),');

    _hasOpenSpan.removeLast();
  }

  @override
  void visitCode(Code code) {
    final spanText = DartCodeSpan(code.textContent).generateTextSpan();

    if (_hasOpenSpan.last) {
      _buffer.write('$spanText,');
    } else {
      _buffer.write('''RichText(text: $spanText, ),''');
    }
  }

  @override
  void visitCodeBlock(CodeBlock code) {
    if (_hasOpenSpan.last) {
      throw 'Invalid state: `CodeBlock`';
    }

    _buffer.write('''
      Padding(
        padding: const EdgeInsets.only(bottom: $_kDefaultItemPadding),
        child: ColoredBox(
          color: colorScheme.background[$_kDefaultBlockBackgroundIndex],
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: const SelectableText(r\'\'\'${code.textContent}\'\'\'),
          ),
        ),
      ),
    ''');

    _previousHeader = null;
  }

  @override
  void visitFencedCodeBlock(FencedCodeBlock code) {
    if (_hasOpenSpan.last) {
      throw 'Invalid state: `FencedCodeBlock`';
    }

    final language = code.language;

    final String spanText;

    switch (language) {
      case 'dart':
        spanText = DartCodeSpan(code.textContent).generateTextSpan();
        break;
      default:
        // TODO(as): See generic code generator.
        spanText = DartCodeSpan(code.textContent).generateTextSpan();
    }

    _buffer.write('''
      Padding(
        padding: const EdgeInsets.only(bottom: $_kDefaultItemPadding),
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all(width: 1.0, color: colorScheme.background[12])),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SelectableText.rich($spanText),
          ),
        ),
      ),
    ''');

    _previousHeader = null;
  }

  final List<bool> _hadBlockQuoteHeader = [];
  int _blockQuoteDepth = 0;

  @override
  void visitBlockQuote(BlockQuote blockQuote) {
    if (_hasOpenSpan.last) {
      throw 'Invalid state: `BlockQuote`';
    }

    final backgroundColor = _blockQuoteDepth.isEven
        ? 'background[0]'
        : 'background[0]';

    _buffer.write('''
      Padding(
        padding: const EdgeInsets.only(bottom: $_kDefaultItemPadding),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 4.0,
                color: colorScheme.background[16],
              ),
            ),
            color: colorScheme.$backgroundColor,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
    ''');

    _blockQuoteDepth += 1;
    _hadBlockQuoteHeader.add(false);

    blockQuote.visitChildren();

    _buffer.write('],),),),),');

    _blockQuoteDepth -= 1;
    _hadBlockQuoteHeader.removeLast();
    _previousHeader = null;
  }

  bool _isNextHeaderLevel(HeaderLevel previousLevel, HeaderLevel level) {
    switch (level) {
      case HeaderLevel.header1:
        return false;
      case HeaderLevel.header2:
        return previousLevel == HeaderLevel.header1;
      case HeaderLevel.header3:
        return previousLevel == HeaderLevel.header2 ||
            _isNextHeaderLevel(previousLevel, HeaderLevel.header2);
      case HeaderLevel.header4:
        return previousLevel == HeaderLevel.header3 ||
            _isNextHeaderLevel(previousLevel, HeaderLevel.header3);
      case HeaderLevel.header5:
        return previousLevel == HeaderLevel.header4 ||
            _isNextHeaderLevel(previousLevel, HeaderLevel.header4);
      case HeaderLevel.header6:
        return previousLevel == HeaderLevel.header5 ||
            _isNextHeaderLevel(previousLevel, HeaderLevel.header5);
    }
  }

  HeaderLevel? _openHeaderLevel;

  @override
  void visitHeader(Header header) {
    if (_hasOpenSpan.last) {
      throw 'Invalid state: `Header`';
    }

    final String textStyle;
    String? topPadding;
    final String bottomPadding;

    _openHeaderLevel = header.level;

    switch (header.level) {
      case HeaderLevel.header1:
        textStyle = 'textTheme.header';
        topPadding = '24.0';
        bottomPadding = '16.0';
        break;
      case HeaderLevel.header2:
        textStyle = 'textTheme.subheader';
        bottomPadding = '16.0';

        if (_previousHeader == null ||
            !_isNextHeaderLevel(_previousHeader!, header.level)) {
          topPadding = '16.0';
        }
        break;
      case HeaderLevel.header3:
        textStyle = 'textTheme.title';
        bottomPadding = '16.0';

        if (_previousHeader == null ||
            !_isNextHeaderLevel(_previousHeader!, header.level)) {
          topPadding = '8.0';
        }
        break;
      case HeaderLevel.header4:
        textStyle = 'textTheme.subtitle';
        bottomPadding = '16.0';

        if (_previousHeader == null ||
            !_isNextHeaderLevel(_previousHeader!, header.level)) {
          topPadding = '8.0';
        }
        break;
      case HeaderLevel.header5:
        textStyle = '''
          TextStyle(
            fontFamily: '$_kFontFamily',
            package: '$_kFontPackage',
            fontWeight: FontWeight.w500,
            fontSize: 18.0,
          )
        ''';

        bottomPadding = '16.0';

        if (_previousHeader == null ||
            !_isNextHeaderLevel(_previousHeader!, header.level)) {
          topPadding = '8.0';
        }
        break;
      case HeaderLevel.header6:
        textStyle = '''
          TextStyle(
            fontFamily: '$_kFontFamily',
            package: '$_kFontPackage',
            fontWeight: FontWeight.w500,
            fontSize: 16.0,
          )
        ''';

        bottomPadding = '16.0';

        if (_previousHeader == null ||
            !_isNextHeaderLevel(_previousHeader!, header.level)) {
          topPadding = '8.0';
        }
        break;
    }

    if (_blockQuoteDepth > 0 && !_hadBlockQuoteHeader.last) {
      topPadding = '0.0';
      _hadBlockQuoteHeader.last = true;
    }

    _isFirstHeader = _buffer.isEmpty;

    _buffer.write('''
      Padding(
      padding: const EdgeInsets.only(
        bottom: $bottomPadding, 
        ${topPadding != null && !_isFirstHeader ? 'top: $topPadding,' : ''}
      ), 
      child: 
        Text.rich(
          TextSpan(
            style: $textStyle,
            children: [
    ''');

    _hasOpenSpan.add(true);
    _lastTextStyle.add(textStyle);

    header.visitChildren();

    _buffer.write('],),),),');

    _previousHeader = header.level;
    _lastTextStyle.removeLast();
    _hasOpenSpan.removeLast();
    _openHeaderLevel = null;
  }

  bool _linkHasTooltip = false;

  @override
  void visitLink(Link link) {
    final Uri uri = Uri.parse(link.url);

    String button = '''
      LinkButton(
        onPressed: () async {
          await launchUrl(
              Uri.parse(r\'\'\'${link.url}\'\'\'),
            );
        },
        style: ${_lastTextStyle.last},
        text: TextSpan(
          children: [
    ''';

    _linkHasTooltip = uri.scheme == 'https';

    if (_linkHasTooltip) {
      button = '''
        Tooltip(
          message: r\'\'\'${link.url}\'\'\',
          child: $button
      ''';
    }

    if (_hasOpenSpan.last) {
      _buffer.write('''
        WidgetSpan(child: $button
      ''');
    } else {
      _buffer.write(button);
    }

    _hasOpenSpan.add(true);

    link.visitChildren();

    _hasOpenSpan.removeLast();

    _buffer.write('],),),');

    if (_linkHasTooltip) {
      _buffer.write('),');
    }

    if (_hasOpenSpan.last) {
      _buffer.write('),');
    }
  }

  @override
  void visitBold(Bold bold) {
    final style = '''
          ${_lastTextStyle.last}.copyWith(
            fontWeight: ${_openHeaderLevel == HeaderLevel.header1 || _openHeaderLevel == HeaderLevel.header2 ? 'FontWeight.w500' : 'FontWeight.w700'},
          )
        ''';

    _lastTextStyle.add(style);

    if (_hasOpenSpan.last) {
      _buffer.write('''TextSpan(style: $style, children: [''');
    } else {
      _buffer.write('''Text.rich(TextSpan(style: $style, children: [''');
    }

    _hasOpenSpan.add(true);

    bold.visitChildren();

    _hasOpenSpan.removeLast();

    if (!_hasOpenSpan.last) {
      _buffer.write('],),),');
    } else {
      _buffer.write('],),');
    }

    _lastTextStyle.removeLast();
  }

  @override
  void visitItalic(Italic italic) {
    final style =
        '''${_lastTextStyle.last}.copyWith(fontStyle: FontStyle.italic)''';

    _lastTextStyle.add(style);

    if (_hasOpenSpan.last) {
      _buffer.write('''TextSpan(style: $style, children: [''');
    } else {
      _buffer.write('''Text.rich(TextSpan(style: $style, children: [''');
    }

    _hasOpenSpan.add(true);

    italic.visitChildren();

    _hasOpenSpan.removeLast();

    if (!_hasOpenSpan.last) {
      _buffer.write('],),),');
    } else {
      _buffer.write('],),');
    }

    _lastTextStyle.removeLast();
  }

  @override
  void visitStrikethrough(Strikethrough strikethrough) {
    final style =
        '''${_lastTextStyle.last}.copyWith(decoration: TextDecoration.lineThrough)''';

    _lastTextStyle.add(style);

    if (_hasOpenSpan.last) {
      _buffer.write('''TextSpan(style: $style, children: [''');
    } else {
      _buffer.write('''Text.rich(TextSpan(style: $style, children: [''');
    }

    _hasOpenSpan.add(true);

    strikethrough.visitChildren();

    _hasOpenSpan.removeLast();

    if (!_hasOpenSpan.last) {
      _buffer.write('],),),');
    } else {
      _buffer.write('],),');
    }

    _lastTextStyle.removeLast();
  }

  @override
  void visitHorizontalRule(HorizontalRule horizontalRule) {
    const widget = '''
      Container(
        margin: const EdgeInsets.only(top: 4.0, bottom: 11.0),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.background[12],
              width: 1.0,
            ),
          ),
        ),
      ),
    ''';

    if (_hasOpenSpan.last) {
      _buffer.write('''
        WidgetSpan(child: $widget, alignment: PlaceholderAlignment.middle),
      ''');
    } else {
      _buffer.write(widget);
    }

    _previousHeader = null;
  }

  int _orderedListDepth = 0;
  final List<int> _orderedListStartNumber = [];

  @override
  void visitOrderedList(OrderedList orderedList) {
    final widget = '''
      Padding(
        padding: const EdgeInsets.only(
          bottom: ${_orderedListDepth == 0 ? '$_kDefaultItemPadding' : '0.0'}, 
          left: ${_orderedListDepth == 0 ? '16.0' : '0.0'}, 
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
    ''';

    _buffer.write(_hasOpenSpan.last ? 'WidgetSpan(child: $widget' : widget);

    _hasOpenSpan.add(false);

    _orderedListStartNumber.add(orderedList.startNumber ?? 1);

    _orderedListDepth += 1;

    orderedList.visitChildren();

    _hasOpenSpan.removeLast();

    if (_hasOpenSpan.last) {
      _buffer.write('],),),),');
    } else {
      _buffer.write('],),),');
    }

    _orderedListStartNumber.removeLast();
    _orderedListDepth -= 1;
    _previousHeader = null;
  }

  @override
  void visitOrderedListItem(OrderedListItem listElement) {
    if (_hasOpenSpan.last) {
      throw 'Invalid state: `OrderedListItem`';
    }

    _buffer.write('''
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: '${_orderedListStartNumber.last}. ', 
              style: textTheme.body1.copyWith(
                fontWeight: FontWeight.bold,
                color: textTheme.textLow,
              ),
              ${listElement.checkbox != null ? '''
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: ${_getCheckboxWidget(listElement.checkbox!)}
                ),
              ],''' : ''}
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
    ''');

    _orderedListStartNumber.last += 1;

    listElement.visitChildren();

    _buffer.write('],),),],),');
  }

  int _unorderedListDepth = 0;

  String _getCheckboxWidget(Checkbox checkbox) {
    return '''
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Checkbox(
          value: ${checkbox.checked.toString()},
          themeData: CheckboxThemeData(
            containerSize: 16.0,
          ),
        ),
      ),
    ''';
  }

  @override
  void visitUnorderedList(UnorderedList unorderedList) {
    final widget = '''
      Padding(
        padding: const EdgeInsets.only(
          bottom: ${_unorderedListDepth == 0 ? '$_kDefaultItemPadding' : '0.0'}, 
          left: ${_unorderedListDepth == 0 ? '16.0' : '0.0'}, 
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
    ''';

    _buffer.write(_hasOpenSpan.last ? 'WidgetSpan(child: $widget' : widget);

    _hasOpenSpan.add(false);

    _unorderedListDepth += 1;

    unorderedList.visitChildren();

    _hasOpenSpan.removeLast();

    if (_hasOpenSpan.last) {
      _buffer.write('],),),),');
    } else {
      _buffer.write('],),),');
    }

    _unorderedListDepth -= 1;
    _previousHeader = null;
  }

  @override
  void visitUnorderedListItem(UnorderedListItem listElement) {
    if (_hasOpenSpan.last) {
      throw 'Invalid state: `UnorderedListItem`';
    }

    final icon = _unorderedListDepth.isOdd
        ? '''
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Icon(
          Icons.circle,
          color: textTheme.textLow,
          size: 8.0,
        ),
      )
    '''
        : '''
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Icon(
          Icons.radio_button_unchecked,
          color: textTheme.textLow,
          size: 8.0,
        ),
      )
    ''';

    _buffer.write('''
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  $icon,
                  ${listElement.checkbox != null ? _getCheckboxWidget(listElement.checkbox!) : ''}
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
    ''');

    listElement.visitChildren();

    _buffer.write('],),),],),');
  }

  @override
  void visitImage(Image image) {
    final widget = '''
      MarkdownImage(
        r\'\'\'${image.destination}\'\'\', 
        alternative: r\'\'\'${image.alternative}\'\'\',
        ${image.title != null ? '''title: r\'\'\'${image.title}\'\'\',''' : ''}
      ),
    ''';

    if (_hasOpenSpan.last) {
      _buffer.write('WidgetSpan(child: $widget),');
    } else {
      _buffer.write(widget);
    }
  }

  List<int> tableCellSizes = [];

  @override
  void visitTable(Table table) {
    if (_hasOpenSpan.last) {
      throw 'Invalid state: `Table`';
    }

    final widget = '''
      Padding(
        padding: const EdgeInsets.only(bottom: $_kDefaultItemPadding), 
        child: ListTable(
          allowColumnDragging: true,
          tableBorder: TableBorder.all(color: colorScheme.shade[30], width: 1.0),
          colCount: ${table.columnCount},
    ''';

    _buffer.write(widget);

    tableCellSizes = List.filled(table.columnCount, 0);

    table.visitChildren();

    final tableCellTotal = tableCellSizes.fold(0, (p, e) => p + e);

    final colFraction = StringBuffer('');

    for (int i = 0; i < table.columnCount; i += 1) {
      colFraction.write('$i: ${tableCellSizes[i] / tableCellTotal},');
    }

    _buffer.write('''
      ],
      colFraction: {$colFraction},
    ),),
    ''');

    _previousHeader = null;
  }

  @override
  void visitTableHeader(TableHeader tableHeader) {
    if (_hasOpenSpan.last) {
      throw 'Invalid state: `TableHeader`';
    }

    const widget = '''
      header: ListTableHeader(
        itemExtent: null,
        children: [
    ''';

    _buffer.write(widget);

    tableHeader.visitChildren();

    _buffer.write('''
      ],),
      rows: [
    ''');
  }

  @override
  void visitTableRow(TableRow tableRow) {
    if (_hasOpenSpan.last) {
      throw 'Invalid state: `TableRow`';
    }

    if (_hasOpenSpan.last) {
      throw 'Invalid state: `TableRow`';
    }

    const widget = '''
      ListTableRow(
        itemExtent: null,
        children: [
    ''';

    _buffer.write(widget);

    tableRow.visitChildren();

    _buffer.write('],),');
  }

  @override
  void visitTableCell(TableCell tableCell) {
    if (_hasOpenSpan.last) {
      throw 'Invalid state: `TableCell`';
    }

    final String alignment;

    switch (tableCell.alignment) {
      case TableCellAlignment.right:
        alignment = 'WrapAlignment.end';
        break;
      case TableCellAlignment.center:
        alignment = 'WrapAlignment.center';
        break;
      case TableCellAlignment.left:
      default:
        alignment = 'WrapAlignment.start';
        break;
    }

    _buffer.write('''
      Padding(
        padding: const EdgeInsets.all($_kDefaultItemPadding),
        child: Wrap(
          alignment: $alignment,
          children: [
    ''');

    tableCell.visitChildren();

    _buffer.write('],),),');

    tableCellSizes[tableCell.columnIndex] = math.max(
      tableCellSizes[tableCell.columnIndex],
      tableCell.textContent.length,
    );
  }
}
