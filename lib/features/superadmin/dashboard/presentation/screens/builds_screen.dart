import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/superadmin_dashboard_api.dart';

/// Every CI build on the platform, newest first.
///
/// The owner-facing build list is scoped to one app; this is the whole
/// picture, so each row has to say which app and owner a build belongs to and
/// link out to the CI run behind it.
class SuperAdminBuildsScreen extends StatefulWidget {
  /// Pre-selects a status filter — used when arriving from a dashboard card.
  final String? initialStatus;

  const SuperAdminBuildsScreen({super.key, this.initialStatus});

  @override
  State<SuperAdminBuildsScreen> createState() => _SuperAdminBuildsScreenState();
}

class _SuperAdminBuildsScreenState extends State<SuperAdminBuildsScreen> {
  static const _statuses = ['QUEUED', 'RUNNING', 'SUCCESS', 'FAILED'];

  late final SuperAdminDashboardApi _api;

  bool _loading = true;
  String? _error;
  String? _status;
  String _query = '';
  List<BuildJobRow> _items = const [];

  @override
  void initState() {
    super.initState();
    _api = SuperAdminDashboardApi(DioClient.ensure());
    _status = widget.initialStatus;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.buildJobs(status: _status);
      final list = (res.data as List).cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        _items = list.map(BuildJobRow.fromJson).toList();
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiErrorHandler.message(e);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<BuildJobRow> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;

    return _items.where((r) {
      return [
        r.appName,
        r.slug,
        r.ownerName,
        r.ownerEmail,
        r.platform,
        r.status,
        r.versionName,
        '${r.ciRunNumber ?? ''}',
      ].join(' ').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.builds_title),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Filters(
              statuses: _statuses,
              selected: _status,
              hint: l10n.builds_search_hint,
              allLabel: l10n.builds_filter_all,
              onSearch: (v) => setState(() => _query = v),
              onStatus: (v) {
                setState(() => _status = v);
                _load();
              },
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_error != null) {
                    return _Message(
                      icon: Icons.error_outline_rounded,
                      title: _error!,
                      actionLabel: l10n.retry,
                      onAction: _load,
                    );
                  }
                  if (rows.isEmpty) {
                    return _Message(
                      icon: Icons.build_circle_outlined,
                      title: l10n.builds_empty,
                    );
                  }

                  return RefreshIndicator.adaptive(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _BuildCard(row: rows[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final List<String> statuses;
  final String? selected;
  final String hint;
  final String allLabel;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;

  const _Filters({
    required this.statuses,
    required this.selected,
    required this.hint,
    required this.allLabel,
    required this.onSearch,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withOpacity(.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(allLabel),
                    selected: selected == null,
                    onSelected: (_) => onStatus(null),
                  ),
                ),
                for (final status in statuses)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: selected == status,
                      onSelected: (_) => onStatus(status),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildCard extends StatelessWidget {
  final BuildJobRow row;

  const _BuildCard({required this.row});

  (Color, IconData) _statusLook(ColorScheme cs) {
    return switch (row.status) {
      'SUCCESS' => (cs.primary, Icons.check_circle_rounded),
      'FAILED' => (cs.error, Icons.error_rounded),
      'RUNNING' => (Colors.blue, Icons.autorenew_rounded),
      _ => (Colors.orange, Icons.schedule_rounded),
    };
  }

  Future<void> _openRun() async {
    final url = row.ciRunUrl;
    if (url == null || url.isEmpty) return;

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final (statusColor, statusIcon) = _statusLook(cs);

    final title = row.appName.trim().isNotEmpty
        ? row.appName.trim()
        : (row.slug.trim().isNotEmpty ? row.slug.trim() : '—');

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(.28)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  row.status,
                  style: tt.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (row.slug.isNotEmpty && row.slug != title) row.slug,
              row.platform,
              if (row.versionName != null && row.versionName!.isNotEmpty)
                row.versionName!,
            ].join(' · '),
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (row.ownerName.isNotEmpty || row.ownerEmail.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 15, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [
                      if (row.ownerName.isNotEmpty) row.ownerName,
                      if (row.ownerEmail.isNotEmpty) row.ownerEmail,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
          if (row.error != null && row.error!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.errorContainer.withOpacity(.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                row.error!.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: cs.onSurface),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatDate(row.createdAt),
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              if (row.ciRunUrl != null && row.ciRunUrl!.isNotEmpty)
                TextButton.icon(
                  onPressed: _openRun,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(
                    row.ciRunNumber != null
                        ? '${l10n.builds_ci_run} #${row.ciRunNumber}'
                        : l10n.builds_ci_run,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// One CI build job across the platform.
class BuildJobRow {
  final int id;
  final int aupId;
  final String appName;
  final String slug;
  final String ownerName;
  final String ownerEmail;
  final String platform;
  final String status;
  final int? ciRunNumber;
  final String? ciRunUrl;
  final String? versionName;
  final DateTime? createdAt;
  final DateTime? finishedAt;
  final String? error;

  BuildJobRow({
    required this.id,
    required this.aupId,
    required this.appName,
    required this.slug,
    required this.ownerName,
    required this.ownerEmail,
    required this.platform,
    required this.status,
    required this.ciRunNumber,
    required this.ciRunUrl,
    required this.versionName,
    required this.createdAt,
    required this.finishedAt,
    required this.error,
  });

  factory BuildJobRow.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    DateTime? parseDt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    String? orNull(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return BuildJobRow(
      id: asInt(j['id']),
      aupId: asInt(j['aupId']),
      appName: (j['appName'] ?? '').toString(),
      slug: (j['slug'] ?? '').toString(),
      ownerName: (j['ownerName'] ?? '').toString(),
      ownerEmail: (j['ownerEmail'] ?? '').toString(),
      platform: (j['platform'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      ciRunNumber: j['ciRunNumber'] == null
          ? null
          : int.tryParse(j['ciRunNumber'].toString()),
      ciRunUrl: orNull(j['ciRunUrl']),
      versionName: orNull(j['versionName']),
      createdAt: parseDt(j['createdAt']),
      finishedAt: parseDt(j['finishedAt']),
      error: orNull(j['error']),
    );
  }
}
