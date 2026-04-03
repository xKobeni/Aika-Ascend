import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

/// Character-by-character animated typing text widget.
class TypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final VoidCallback? onComplete;
  final bool showCursor;

  const TypingText({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 40),
    this.onComplete,
    this.showCursor = true,
  });

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText>
    with SingleTickerProviderStateMixin {
  String _displayed = '';
  int _charIndex = 0;
  Timer? _timer;
  late AnimationController _cursorController;
  late Animation<double> _cursorAnim;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _cursorAnim = Tween<double>(begin: 0, end: 1).animate(_cursorController);
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.charDuration, (t) {
      if (_charIndex >= widget.text.length) {
        t.cancel();
        widget.onComplete?.call();
        return;
      }
      setState(() {
        _displayed += widget.text[_charIndex];
        _charIndex++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        GoogleFonts.shareTechMono(color: AppColors.cyan, fontSize: 13);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(child: Text(_displayed, style: style)),
        if (widget.showCursor)
          AnimatedBuilder(
            animation: _cursorAnim,
            builder: (_, __) => Opacity(
              opacity: _cursorAnim.value,
              child: Text('█', style: style.copyWith(fontSize: (style.fontSize ?? 13) * 0.8)),
            ),
          ),
      ],
    );
  }
}
