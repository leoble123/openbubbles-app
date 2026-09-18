import 'package:bluebubbles/echo/glass/glass_surface.dart';
import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:flutter/material.dart';

/// Shows a glass bottom sheet that rises from the edge with a short spring,
/// over a dimmed and blurred backdrop (spec §12).
///
/// [anchorPadding] lets a sheet sit visually connected to the control that
/// opened it — the attachment sheet uses it to hug the composer.
Future<T?> showEchoSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool expandable = false,
  double? maxHeightFraction,
  EdgeInsets anchorPadding = const EdgeInsets.fromLTRB(
    EchoTokens.space3,
    0,
    EchoTokens.space3,
    EchoTokens.space3,
  ),
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: EchoTokens.medium,
    pageBuilder: (context, animation, secondary) {
      final media = MediaQuery.of(context);
      return _EchoBackdrop(
        animation: animation,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: anchorPadding.copyWith(bottom: anchorPadding.bottom + media.viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: media.size.height * (maxHeightFraction ?? (expandable ? 0.88 : 0.66)),
              ),
              child: GlassSurface(
                level: 3,
                radius: EchoTokens.radiusXl,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _GrabHandle(),
                      Flexible(child: builder(context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: EchoTokens.spring,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// A floating glass dialog that arrives with depth rather than a flat fade
/// (spec §12/§15).
Future<T?> showEchoDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: EchoTokens.medium,
    pageBuilder: (context, animation, secondary) => _EchoBackdrop(
      animation: animation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(EchoTokens.space5),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GlassSurface(
              level: 3,
              radius: EchoTokens.radiusXl,
              child: builder(context),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: EchoTokens.easeOut);
      return FadeTransition(
        opacity: animation,
        // Scaling in from slightly behind reads as the surface coming forward
        // through the blur, instead of a flat Android fade.
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Dim + blur behind a modal surface, animated in with the surface itself.
class _EchoBackdrop extends StatelessWidget {
  const _EchoBackdrop({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, inner) {
        final t = animation.value;
        final sigma = 14.0 * t * EchoGlass.blurScale;
        Widget barrier = ColoredBox(color: Colors.black.withOpacity(0.55 * t));
        if (sigma >= 0.5) {
          barrier = BackdropFilter(filter: EchoBlur.of(sigma), child: barrier);
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: barrier,
            ),
            inner!,
          ],
        );
      },
      child: child,
    );
  }
}

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: EchoTokens.space3, bottom: EchoTokens.space2),
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.22),
          borderRadius: BorderRadius.circular(EchoTokens.radiusCapsule),
        ),
      ),
    );
  }
}
