import 'package:flutter/material.dart';

/// Branded full-screen loader.
///
/// Deliberately mirrors the HTML splash in `web/index.html` (same card, same
/// logo, same brand-coloured bar) so the hand-off from "page is downloading"
/// to "app is deciding where to send you" reads as one continuous screen
/// instead of two different loading states.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({
    super.key,
    this.title = 'Build4All Manager',
    this.message,
  });

  final String title;

  /// Optional status line under the progress bar.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fixed box so the layout never shifts once the logo decodes.
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Image.asset(
                    'assets/icon/app_logo_192.png',
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    frameBuilder: (_, child, frame, wasSyncLoaded) {
                      if (wasSyncLoaded || frame != null) return child;
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 22),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
