import 'package:flutter/material.dart';

/// Subtle gradient at the bottom when scrollable content continues below the fold.
class ScrollBottomFade extends StatefulWidget {
  const ScrollBottomFade.builder({
    super.key,
    required this.fadeColor,
    required this.builder,
    this.fadeHeight = 56,
  });

  final Color fadeColor;
  final double fadeHeight;
  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  @override
  State<ScrollBottomFade> createState() => _ScrollBottomFadeState();
}

class _ScrollBottomFadeState extends State<ScrollBottomFade> {
  late final ScrollController _controller;
  bool _showFade = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_updateFade);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateFade() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final canScroll = position.maxScrollExtent > 0;
    final atBottom = position.pixels >= position.maxScrollExtent - 8;
    final show = canScroll && !atBottom;
    if (show != _showFade && mounted) {
      setState(() => _showFade = show);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFade());

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollMetricsNotification ||
                notification is ScrollUpdateNotification) {
              _updateFade();
            }
            return false;
          },
          child: widget.builder(context, _controller),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showFade ? 1 : 0,
              child: Container(
                height: widget.fadeHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.fadeColor.withValues(alpha: 0),
                      widget.fadeColor.withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
