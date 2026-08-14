import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ci_run_info.dart';

/// Tappable pill linking to the run. Render it only when [CiRunInfo.showLink].
class CiRunChip extends StatelessWidget {
  final CiRunInfo info;

  /// Trims the chip down for dense rows, where the run number alone carries it.
  final bool dense;

  const CiRunChip({
    super.key,
    required this.info,
    this.dense = false,
  });

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse((info.ciRunUrl ?? '').trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final tint = info.isFailed ? cs.error : cs.primary;

    final label = info.ciRunNumber != null
        ? l10n.publish_ci_run_number(info.ciRunNumber!)
        : l10n.publish_ci_run_open_logs;

    return Tooltip(
      message: l10n.publish_ci_run_open_logs,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _open(context),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 8 : 10,
            vertical: dense ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: tint.withOpacity(.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.terminal_rounded, size: dense ? 13 : 14, color: tint),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tint,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.open_in_new_rounded, size: 12, color: tint),
            ],
          ),
        ),
      ),
    );
  }
}
