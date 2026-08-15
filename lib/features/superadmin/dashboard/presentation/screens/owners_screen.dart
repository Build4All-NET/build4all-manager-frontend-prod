import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/superadmin_dashboard_api.dart';

/// Every app owner on the platform, with the contact details needed to reach
/// them and how many apps each one holds.
class SuperAdminOwnersScreen extends StatefulWidget {
  const SuperAdminOwnersScreen({super.key});

  @override
  State<SuperAdminOwnersScreen> createState() => _SuperAdminOwnersScreenState();
}

class _SuperAdminOwnersScreenState extends State<SuperAdminOwnersScreen> {
  late final SuperAdminDashboardApi _api;

  bool _loading = true;
  String? _error;
  String _query = '';
  List<OwnerRow> _items = const [];

  @override
  void initState() {
    super.initState();
    _api = SuperAdminDashboardApi(DioClient.ensure());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.owners();
      final list = (res.data as List).cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        _items = list.map(OwnerRow.fromJson).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiErrorHandler.message(e);
        _loading = false;
      });
    }
  }

  List<OwnerRow> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;

    return _items.where((o) {
      return [o.name, o.username, o.email, o.phoneNumber ?? '']
          .join(' ')
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final rows = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.owners_title),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: l10n.owners_search_hint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 40, color: cs.error),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 14),
                            OutlinedButton(
                              onPressed: _load,
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (rows.isEmpty) {
                    return Center(child: Text(l10n.owners_empty));
                  }

                  return RefreshIndicator.adaptive(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _OwnerCard(owner: rows[i]),
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

class _OwnerCard extends StatelessWidget {
  final OwnerRow owner;

  const _OwnerCard({required this.owner});

  Future<void> _launch(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final name = owner.name.trim().isNotEmpty
        ? owner.name.trim()
        : (owner.username.trim().isNotEmpty ? owner.username.trim() : '—');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primary.withOpacity(.12),
            child: Text(
              name.characters.first.toUpperCase(),
              style: tt.titleMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (owner.username.trim().isNotEmpty)
                  Text(
                    '@${owner.username.trim()}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                const SizedBox(height: 8),
                if (owner.email.trim().isNotEmpty)
                  _ContactLine(
                    icon: Icons.mail_outline_rounded,
                    text: owner.email.trim(),
                    onTap: () => _launch(
                      Uri(scheme: 'mailto', path: owner.email.trim()),
                    ),
                  ),
                if (owner.phoneNumber != null)
                  _ContactLine(
                    icon: Icons.phone_outlined,
                    text: owner.phoneNumber!,
                    onTap: () => _launch(
                      Uri(scheme: 'tel', path: owner.phoneNumber!),
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: owner.appsCount > 0
                        ? cs.primary.withOpacity(.10)
                        : cs.surfaceContainerHighest.withOpacity(.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${owner.appsCount} ${l10n.owners_apps_count}',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: owner.appsCount > 0
                          ? cs.primary
                          : cs.onSurfaceVariant,
                    ),
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

class _ContactLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ContactLine({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One app owner with contact details and how many apps they hold.
class OwnerRow {
  final int adminId;
  final String name;
  final String username;
  final String email;
  final String? phoneNumber;
  final int appsCount;

  OwnerRow({
    required this.adminId,
    required this.name,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.appsCount,
  });

  factory OwnerRow.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    String? orNull(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return OwnerRow(
      adminId: asInt(j['adminId']),
      name: (j['name'] ?? '').toString(),
      username: (j['username'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      phoneNumber: orNull(j['phoneNumber']),
      appsCount: asInt(j['appsCount']),
    );
  }
}
