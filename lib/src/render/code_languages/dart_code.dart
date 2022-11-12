// Copyright (c) 2022, Adriano Souza. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.

/// Generates a text span for a code block in markdown.
class DartCodeSpan {
  ///
  DartCodeSpan(this.text);

  /// The input text;
  final String text;

  static final _regex = RegExp(
    r'''(?<class>\b[_$]*[A-Z][a-zA-Z0-9_$]*\b|bool\b|num\b|int\b|double\b|dynamic\b|(void)\b)|(?<string>(?:'.*?'))|(?<keyword>\b(?:try|on|catch|finally|throw|rethrow|break|case|continue|default|do|else|for|if|in|return|switch|while|abstract|class|enum|extends|extension|external|factory|implements|get|mixin|native|operator|set|typedef|with|covariant|static|final|const|required|late|void|var|library|import|part of|part|export|await|yield|async|sync|true|false|null)\b)|(?<comment>(?:(?:\/.*?)$))|(?<numeric>\b(?:(?:0(?:x|X)[0-9a-fA-F]*)|(?:(?:[0-9]+\.?[0-9]*)|(?:\.[0-9]+))(?:(?:e|E)(?:\+|-)?[0-9]+)?)\b)''',
    multiLine: true,
    dotAll: true,
  );

  /// Generates the text span code.
  String generateTextSpan() {
    const textColor = 'textTheme.textHigh';

    final String classColor;
    final String commentsColor;
    final String stringColor;
    final String keywordColor;
    final String numericColor;

    if (true) {
      classColor = 'const Color(0xff5ecda8)';
      commentsColor = 'const Color(0xff696969)';
      stringColor = 'const Color(0xffdc8c6a)';
      keywordColor = 'const Color(0xff60b5f6)';
      numericColor = 'const Color(0xffc2dcb5)';
    } else {
      // classColor = const Color(0xff418D73);
      // commentsColor = const Color(0xff969696);
      // stringColor = const Color(0xffB37256);
      // keywordColor = const Color(0xff4684B3);
      // numericColor = const Color(0xff92A688);
    }

    final matches = _regex.allMatches(text);

    final spans = StringBuffer('');

    int lastEnd = 0;

    String getText(int start, [int? end]) {
      return '''
        String.fromCharCodes(const ${text.substring(start, end).codeUnits.fold('[', (p, e) => '$p 0x${e.toRadixString(0x10)},')}])
      ''';
    }

    for (final match in matches) {
      final start = match.start;
      final end = match.end;

      spans.write('''
        TextSpan(text: ${getText(lastEnd, start)}),
      ''');

      if (match.namedGroup('class') != null) {
        spans.write('''
          TextSpan(
            text: ${getText(start, end)},
            style: TextStyle(color: $classColor),
          ),
        ''');
      } else if (match.namedGroup('keyword') != null) {
        spans.write('''
          TextSpan(
            text:  ${getText(start, end)},
            style: TextStyle(color: $keywordColor),
          ),
        ''');
      } else if (match.namedGroup('string') != null) {
        spans.write('''
          TextSpan(
            text: ${getText(start, end)},
            style: TextStyle(color: $stringColor),
          ),
        ''');
      } else if (match.namedGroup('comment') != null) {
        spans.write('''
          TextSpan(
            text: ${getText(start, end)},
            style: TextStyle(color: $commentsColor),
          ),
        ''');
      } else if (match.namedGroup('numeric') != null) {
        spans.write('''
          TextSpan(
            text: ${getText(start, end)},
            style: TextStyle(color: $numericColor),
          ),
        ''');
      } else {
        spans.write('''
          TextSpan(
            text: ${getText(start, end)},
          ),
        ''');
      }

      lastEnd = end;
    }

    spans.write('''
      TextSpan(text: ${getText(lastEnd)}),
    ''');

    return '''
      TextSpan(
        style: textTheme.monospace.copyWith(color: $textColor),
        children: [$spans],
      )
    ''';
  }
}
