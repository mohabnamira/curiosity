import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:curiosity/widgets/citation_chip.dart';

class CitationSyntax extends md.InlineSyntax {
  CitationSyntax() : super(r'(?:\[\d+\])+');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final matchedText = match.group(0)!;
    final singleRegex = RegExp(r'\[(\d+)\]');
    final nums = <int>[];

    for (final m in singleRegex.allMatches(matchedText)) {
      final n = int.tryParse(m.group(1)!);
      if (n != null) nums.add(n);
    }

    final el = md.Element.text('citation', matchedText);
    el.attributes['indices'] = nums.join(',');
    parser.addNode(el);
    return true;
  }
}

class CitationElementBuilder extends MarkdownElementBuilder {
  final List<String> sourceUrls;
  final ValueChanged<int>? onCitationTap;

  CitationElementBuilder({
    required this.sourceUrls,
    this.onCitationTap,
  });

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final indicesStr = element.attributes['indices'] ?? '';
    final rawNums = indicesStr
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();

    // Filter to valid 1-based source indices, convert to 0-based
    final valid0Based = rawNums
        .where((n) => n >= 1 && n <= sourceUrls.length)
        .map((n) => n - 1)
        .toSet()
        .toList();

    if (valid0Based.isEmpty) {
      // If citation has no matching source, render plain text
      return Text(
        element.textContent,
        style: preferredStyle,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: CitationGroupWidget(
        sourceIndices: valid0Based,
        sourceUrls: sourceUrls,
        onCitationTap: onCitationTap,
      ),
    );
  }
}
