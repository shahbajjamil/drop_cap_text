import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

enum DropCapMode {
  /// default
  inside,
  upwards,
  aside,

  /// Does not support dropCapPadding, indentation, dropCapPosition and custom dropCap.
  /// Try using DropCapMode.upwards in combination with dropCapPadding and forceNoDescent=true
  baseline
}

enum DropCapPosition {
  start,
  end,
}

class DropCap extends StatelessWidget {
  final Widget child;
  final double width, height;

  DropCap({
    Key? key,
    required this.child,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(child: child, width: width, height: height);
  }
}

class DropCapText extends StatefulWidget {
  final String data;
  final DropCapMode mode;
  final TextStyle? style, dropCapStyle, readMoreStyle;
  final TextAlign textAlign;
  final DropCap? dropCap;
  final EdgeInsets dropCapPadding;
  final Offset indentation;
  final bool forceNoDescent, parseInlineMarkdown;
  final TextDirection textDirection;
  final DropCapPosition? dropCapPosition;
  final int dropCapChars;
  final int? maxLines;
  final TextOverflow overflow;
  final bool readMore;
  final int breakingLength;

  DropCapText(this.data,
      {Key? key,
      this.mode = DropCapMode.inside,
      this.style,
      this.dropCapStyle,
      this.textAlign = TextAlign.start,
      this.dropCap,
      this.dropCapPadding = EdgeInsets.zero,
      this.indentation = Offset.zero,
      this.dropCapChars = 1,
      this.forceNoDescent = false,
      this.parseInlineMarkdown = false,
      this.textDirection = TextDirection.ltr,
      this.overflow = TextOverflow.clip,
      this.maxLines,
      this.dropCapPosition,
      this.readMore = false,
      this.breakingLength = 150,
      this.readMoreStyle})
      : super(key: key);

  @override
  State<DropCapText> createState() => _DropCapTextState();
}

class _DropCapTextState extends State<DropCapText> {
  bool isReadMore = false;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = TextStyle(
      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
      fontSize: 14,
      height: 1,
      fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
    ).merge(widget.style);

    if (widget.data == '') return Text(widget.data, style: textStyle);

    TextStyle capStyle = TextStyle(
      color: textStyle.color,
      fontSize: textStyle.fontSize! * 5.5,
      fontFamily: textStyle.fontFamily,
      fontWeight: textStyle.fontWeight,
      fontStyle: textStyle.fontStyle,
      height: 1,
    ).merge(widget.dropCapStyle);

    double capWidth, capHeight;
    int dropCapChars = widget.dropCap != null ? 0 : this.widget.dropCapChars;
    CrossAxisAlignment sideCrossAxisAlignment = CrossAxisAlignment.start;
    MarkdownParser? mdData =
        widget.parseInlineMarkdown ? MarkdownParser(widget.data) : null;
    final String dropCapStr =
        (mdData?.plainText ?? widget.data).substring(0, dropCapChars);

    if (widget.mode == DropCapMode.baseline && widget.dropCap == null)
      return _buildBaseline(context, textStyle, capStyle);

    // custom DropCap
    if (widget.dropCap != null) {
      capWidth = widget.dropCap!.width;
      capHeight = widget.dropCap!.height;
    } else {
      TextPainter capPainter = TextPainter(
        text: TextSpan(
          text: dropCapStr,
          style: capStyle,
        ),
        textDirection: widget.textDirection,
      );
      capPainter.layout();
      capWidth = capPainter.width;
      capHeight = capPainter.height;
      if (widget.forceNoDescent) {
        List<LineMetrics> ls = capPainter.computeLineMetrics();
        capHeight -=
            ls.isNotEmpty ? ls[0].descent * 0.95 : capPainter.height * 0.2;
      }
    }

    // compute drop cap padding
    capWidth += widget.dropCapPadding.left + widget.dropCapPadding.right;
    capHeight += widget.dropCapPadding.top + widget.dropCapPadding.bottom;

    MarkdownParser? mdRest =
        widget.parseInlineMarkdown ? mdData!.subchars(dropCapChars) : null;
    String restData = widget.data.substring(dropCapChars);

    TextSpan textSpan = TextSpan(
      text: widget.parseInlineMarkdown ? null : restData,
      children: widget.parseInlineMarkdown ? mdRest!.toTextSpanList() : null,
      style: textStyle.apply(
          fontSizeFactor:
              MediaQuery.of(context).textScaler.scale(textStyle.fontSize!)),
    );

    TextPainter textPainter = TextPainter(
        textDirection: widget.textDirection,
        text: textSpan,
        textAlign: widget.textAlign);
    double lineHeight = textPainter.preferredLineHeight;

    int rows = ((capHeight - widget.indentation.dy) / lineHeight).ceil();

    // DROP CAP MODE - UPWARDS
    if (widget.mode == DropCapMode.upwards) {
      rows = 1;
      sideCrossAxisAlignment = CrossAxisAlignment.end;
    }

    // BUILDER
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double boundsWidth = constraints.maxWidth - capWidth;
      if (boundsWidth < 1) boundsWidth = 1;

      int charIndexEnd = widget.data.length;

      //int startMillis = new DateTime.now().millisecondsSinceEpoch;
      if (rows > 0) {
        textPainter.layout(maxWidth: boundsWidth);
        double yPos = rows * lineHeight;
        int charIndex =
            textPainter.getPositionForOffset(Offset(0, yPos)).offset;
        textPainter.maxLines = rows;
        textPainter.layout(maxWidth: boundsWidth);
        if (textPainter.didExceedMaxLines) charIndexEnd = charIndex;
      } else {
        charIndexEnd = dropCapChars;
      }
      //int totMillis = new DateTime.now().millisecondsSinceEpoch - startMillis;

      // DROP CAP MODE - LEFT
      if (widget.mode == DropCapMode.aside) charIndexEnd = widget.data.length;
      // print("restData.length ${restData.length}");
      // print("charIndexEnd $charIndexEnd");
      // print("widget.data ${widget.data.length}");
      String restEndData =
          restData.substring(min(charIndexEnd, restData.length));
      // print("widget.restData.char: ${restEndData} : ${restEndData.length}");
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Text(totMillis.toString() + ' ms'),
          Row(
            textDirection: widget.dropCapPosition == null ||
                    widget.dropCapPosition == DropCapPosition.start
                ? widget.textDirection
                : (widget.textDirection == TextDirection.ltr
                    ? TextDirection.rtl
                    : TextDirection.ltr),
            crossAxisAlignment: sideCrossAxisAlignment,
            children: <Widget>[
              widget.dropCap != null
                  ? Padding(
                      padding: widget.dropCapPadding, child: widget.dropCap)
                  : Container(
                      width: capWidth,
                      height: capHeight,
                      padding: widget.dropCapPadding,
                      child: RichText(
                        textDirection: widget.textDirection,
                        textAlign: widget.textAlign,
                        text: TextSpan(
                          text: dropCapStr,
                          style: capStyle,
                        ),
                      ),
                    ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.only(top: widget.indentation.dy),
                  width: boundsWidth,
                  height: widget.mode != DropCapMode.aside
                      ? (lineHeight * min(widget.maxLines ?? rows, rows)) +
                          widget.indentation.dy
                      : null,
                  child: RichText(
                    overflow: (widget.maxLines == null ||
                            (widget.maxLines! > rows &&
                                widget.overflow == TextOverflow.fade))
                        ? TextOverflow.clip
                        : widget.overflow,
                    maxLines: widget.maxLines,
                    textDirection: widget.textDirection,
                    textAlign: widget.textAlign,
                    text: textSpan,
                  ),
                ),
              ),
            ],
          ),
          if ((widget.maxLines == null || widget.maxLines! > rows) &&
              restEndData.length > 0)
            if (!widget.readMore)
              Padding(
                padding: EdgeInsets.only(left: widget.indentation.dx),
                child: RichText(
                  overflow: widget.overflow,
                  maxLines: widget.maxLines != null && widget.maxLines! > rows
                      ? widget.maxLines! - rows
                      : null,
                  textAlign: widget.textAlign,
                  textDirection: widget.textDirection,
                  text: TextSpan(
                    text: widget.parseInlineMarkdown ? null : restEndData,
                    children: widget.parseInlineMarkdown
                        ? mdRest!.subchars(charIndexEnd).toTextSpanList()
                        : null,
                    style: textStyle.apply(
                        fontSizeFactor: MediaQuery.of(context).textScaler.scale(textStyle.fontSize!)),
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(left: widget.indentation.dx),
                child: RichText(
                  overflow: widget.overflow,
                  maxLines: widget.maxLines != null && widget.maxLines! > rows
                      ? widget.maxLines! - rows
                      : null,
                  textAlign: widget.textAlign,
                  textDirection: widget.textDirection,
                  text: TextSpan(
                    style:
                        widget.style ?? Theme.of(context).textTheme.bodyMedium!,
                    children: [
                      isReadMore
                          ? TextSpan(
                              text: widget.parseInlineMarkdown
                                  ? null
                                  : restEndData,
                              style: widget.style ??
                                  Theme.of(context).textTheme.bodyMedium!)
                          : restData.length > widget.breakingLength
                              ? TextSpan(
                                  text: widget.parseInlineMarkdown
                                      ? null
                                      : restData
                                          .substring(min(
                                              charIndexEnd, restData.length))
                                          .substring(
                                              0,
                                              restData.length >
                                                      widget.breakingLength
                                                  ? widget.breakingLength
                                                  : restData.length),
                                  style: widget.style ??
                                      Theme.of(context).textTheme.bodyMedium!)
                              : TextSpan(
                                  text: widget.parseInlineMarkdown
                                      ? null
                                      : restEndData,
                                  style: widget.style ??
                                      Theme.of(context).textTheme.bodyMedium!),
                      if (!isReadMore &&
                          restData.length > widget.breakingLength)
                        TextSpan(
                            text: "...",
                            style: widget.style ??
                                Theme.of(context).textTheme.bodyMedium),
                      if (restData.length > widget.breakingLength)
                        TextSpan(
                          text: isReadMore ? " Read Less" : " Read More",
                          style: widget.readMoreStyle ??
                              textStyle.apply(
                                  fontSizeFactor:
                                      MediaQuery.of(context).textScaler.scale(textStyle.fontSize!)),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              setState(() => isReadMore = !isReadMore);
                            },
                        ),
                    ],
                  ),
                ),
              ),
        ],
      );
    });
  }

  _buildBaseline(
      BuildContext context, TextStyle textStyle, TextStyle capStyle) {
    MarkdownParser mdData = MarkdownParser(widget.data);

    return RichText(
      textAlign: widget.textAlign,
      text: TextSpan(
        style: textStyle,
        children: <TextSpan>[
          TextSpan(
            text: mdData.plainText.substring(0, widget.dropCapChars),
            style: capStyle.merge(TextStyle(height: 0)),
          ),
          TextSpan(
            children: mdData.subchars(widget.dropCapChars).toTextSpanList(),
            style: textStyle.apply(
                fontSizeFactor: MediaQuery.of(context).textScaler.scale(textStyle.fontSize!)),
          ),
        ],
      ),
    );
  }
}

class MarkdownParser {
  final String data;
  late List<MarkdownSpan> spans;
  String plainText = '';

  List<TextSpan> toTextSpanList() {
    return spans.map((s) => s.toTextSpan()).toList();
  }

  MarkdownParser subchars(int startIndex, [int? endIndex]) {
    final List<MarkdownSpan> subspans = [];
    int skip = startIndex;
    for (int s = 0; s < spans.length; s++) {
      MarkdownSpan span = spans[s];
      if (skip <= 0) {
        subspans.add(span);
      } else if (span.text.length < skip) {
        skip -= span.text.length;
      } else {
        subspans.add(
          MarkdownSpan(
            style: span.style,
            markups: span.markups,
            text: span.text.substring(skip, span.text.length),
          ),
        );
        skip = 0;
      }
    }

    return MarkdownParser(
      subspans
          .asMap()
          .map((int index, MarkdownSpan span) {
            String markup = index > 0
                ? (span.markups.isNotEmpty ? span.markups[0].code : '')
                : span.markups.map((m) => m.isActive ? m.code : '').join();
            return MapEntry(index, '$markup${span.text}');
          })
          .values
          .toList()
          .join(),
    );
  }

  MarkdownParser(this.data) {
    plainText = '';
    spans = [MarkdownSpan(text: '', markups: [], style: TextStyle())];

    bool bold = false;
    bool italic = false;
    bool underline = false;

    const String MARKUP_BOLD = '**';
    const String MARKUP_ITALIC = '_';
    const String MARKUP_UNDERLINE = '++';

    addSpan(String markup, bool isOpening) {
      final List<Markup> markups = [Markup(markup, isOpening)];

      if (bold && markup != MARKUP_BOLD) markups.add(Markup(MARKUP_BOLD, true));
      if (italic && markup != MARKUP_ITALIC)
        markups.add(Markup(MARKUP_ITALIC, true));
      if (underline && markup != MARKUP_UNDERLINE)
        markups.add(Markup(MARKUP_UNDERLINE, true));

      spans.add(
        MarkdownSpan(
          text: '',
          markups: markups,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : null,
            fontStyle: italic ? FontStyle.italic : null,
            decoration: underline ? TextDecoration.underline : null,
          ),
        ),
      );
    }

    bool checkMarkup(int i, String markup) {
      return data.substring(i, min(i + markup.length, data.length)) == markup;
    }

    for (int c = 0; c < data.length; c++) {
      if (checkMarkup(c, MARKUP_BOLD)) {
        bold = !bold;
        addSpan(MARKUP_BOLD, bold);
        c += MARKUP_BOLD.length - 1;
      } else if (checkMarkup(c, MARKUP_ITALIC)) {
        italic = !italic;
        addSpan(MARKUP_ITALIC, italic);
        c += MARKUP_ITALIC.length - 1;
      } else if (checkMarkup(c, MARKUP_UNDERLINE)) {
        underline = !underline;
        addSpan(MARKUP_UNDERLINE, underline);
        c += MARKUP_UNDERLINE.length - 1;
      } else {
        spans[spans.length - 1].text += data[c];
        plainText += data[c];
      }
    }
  }
}

class MarkdownSpan {
  final TextStyle style;
  final List<Markup> markups;
  String text;

  TextSpan toTextSpan() => TextSpan(text: text, style: style);

  MarkdownSpan({
    required this.text,
    required this.style,
    required this.markups,
  });
}

class Markup {
  final String code;
  final bool isActive;

  Markup(this.code, this.isActive);
}
