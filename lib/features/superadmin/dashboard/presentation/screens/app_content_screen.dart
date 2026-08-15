import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:flutter/material.dart';

import '../../data/services/superadmin_dashboard_api.dart';

/// Read-only window into one app's content: how much it holds, its catalogue,
/// and its end users.
///
/// Support tooling — the content belongs to the owner, so nothing here edits
/// it. Loading is per tab so opening the screen does not pull a catalogue and
/// a customer list nobody asked for.
class AppContentScreen extends StatefulWidget {
  final int aupId;

  /// Shown in the app bar until the summary arrives with the real name.
  final String appTitle;

  const AppContentScreen({
    super.key,
    required this.aupId,
    required this.appTitle,
  });

  @override
  State<AppContentScreen> createState() => _AppContentScreenState();
}

class _AppContentScreenState extends State<AppContentScreen>
    with SingleTickerProviderStateMixin {
  late final SuperAdminDashboardApi _api;
  late final TabController _tabs;

  AppContentSummary? _summary;
  String? _summaryError;
  bool _loadingSummary = true;

  List<AppItemRow>? _items;
  String? _itemsError;
  bool _loadingItems = false;

  List<AppCustomerRow>? _customers;
  String? _customersError;
  bool _loadingCustomers = false;

  @override
  void initState() {
    super.initState();
    _api = SuperAdminDashboardApi(DioClient.ensure());
    _tabs = TabController(length: 2, vsync: this)..addListener(_onTabChanged);
    _loadSummary();
    _loadItems();
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    if (_tabs.index == 1 && _customers == null && !_loadingCustomers) {
      _loadCustomers();
    }
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loadingSummary = true;
      _summaryError = null;
    });

    try {
      final res = await _api.appContentSummary(widget.aupId);
      if (!mounted) return;
      setState(() {
        _summary = AppContentSummary.fromJson(
          Map<String, dynamic>.from(res.data as Map),
        );
        _loadingSummary = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summaryError = ApiErrorHandler.message(e);
        _loadingSummary = false;
      });
    }
  }

  Future<void> _loadItems() async {
    setState(() {
      _loadingItems = true;
      _itemsError = null;
    });

    try {
      final res = await _api.appItems(widget.aupId);
      final list = (res.data as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _items = list.map(AppItemRow.fromJson).toList();
        _loadingItems = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _itemsError = ApiErrorHandler.message(e);
        _loadingItems = false;
      });
    }
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _loadingCustomers = true;
      _customersError = null;
    });

    try {
      final res = await _api.appCustomers(widget.aupId);
      final list = (res.data as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _customers = list.map(AppCustomerRow.fromJson).toList();
        _loadingCustomers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _customersError = ApiErrorHandler.message(e);
        _loadingCustomers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = _summary;

    final title = (summary?.appName.trim().isNotEmpty ?? false)
        ? summary!.appName.trim()
        : widget.appTitle;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              l10n.app_content_title,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.app_content_tab_items),
            Tab(text: l10n.app_content_tab_customers),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _SummaryStrip(
              loading: _loadingSummary,
              error: _summaryError,
              summary: summary,
              onRetry: _loadSummary,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ItemsTab(
                    loading: _loadingItems,
                    error: _itemsError,
                    items: _items,
                    onRetry: _loadItems,
                  ),
                  _CustomersTab(
                    loading: _loadingCustomers,
                    error: _customersError,
                    customers: _customers,
                    onRetry: _loadCustomers,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final bool loading;
  final String? error;
  final AppContentSummary? summary;
  final VoidCallback onRetry;

  const _SummaryStrip({
    required this.loading,
    required this.error,
    required this.summary,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(minHeight: 3),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
            const SizedBox(width: 8),
            Expanded(child: Text(error!, style: TextStyle(color: cs.error))),
            TextButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    final s = summary;
    if (s == null) return const SizedBox.shrink();

    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        children: [
          _CountChip(
            icon: Icons.inventory_2_outlined,
            label: l10n.app_content_items,
            value: s.items,
          ),
          _CountChip(
            icon: Icons.category_outlined,
            label: l10n.app_content_categories,
            value: s.categories,
          ),
          _CountChip(
            icon: Icons.people_outline_rounded,
            label: l10n.app_content_customers,
            value: s.customers,
          ),
          _CountChip(
            icon: Icons.receipt_long_outlined,
            label: l10n.app_content_orders,
            value: s.orders,
          ),
          _CountChip(
            icon: Icons.storefront_outlined,
            label: l10n.app_content_shops,
            value: s.shops,
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _CountChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsetsDirectional.only(end: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(
                '$value',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemsTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<AppItemRow>? items;
  final VoidCallback onRetry;

  const _ItemsTab({
    required this.loading,
    required this.error,
    required this.items,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return _TabMessage(message: error!, actionLabel: l10n.retry, onAction: onRetry);
    }

    final rows = items ?? const <AppItemRow>[];
    if (rows.isEmpty) {
      return _TabMessage(message: l10n.app_content_items_empty);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final item = rows[i];
        final tt = Theme.of(context).textTheme;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2_outlined,
                    size: 20, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name.isNotEmpty ? item.name : '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (item.type != null) item.type!,
                        if (item.sku != null) 'SKU ${item.sku}',
                        if (item.shopName != null) item.shopName!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (item.price != null)
                          _MiniChip(
                            text: item.salePrice != null
                                ? '${item.salePrice} (${item.price})'
                                : '${item.price}',
                            color: cs.primary,
                          ),
                        if (item.status != null)
                          _MiniChip(text: item.status!, color: cs.secondary),
                        _MiniChip(
                          text: '${l10n.app_content_stock}: ${item.stock ?? 0}',
                          color: (item.stock ?? 0) > 0
                              ? cs.tertiary
                              : cs.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomersTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<AppCustomerRow>? customers;
  final VoidCallback onRetry;

  const _CustomersTab({
    required this.loading,
    required this.error,
    required this.customers,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return _TabMessage(message: error!, actionLabel: l10n.retry, onAction: onRetry);
    }

    final rows = customers ?? const <AppCustomerRow>[];
    if (rows.isEmpty) {
      return _TabMessage(message: l10n.app_content_customers_empty);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final customer = rows[i];
        final name = customer.name.isNotEmpty ? customer.name : '—';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primary.withOpacity(.12),
                child: Text(
                  name.characters.first.toUpperCase(),
                  style: tt.titleSmall?.copyWith(
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (customer.verified == true)
                          Icon(Icons.verified_rounded,
                              size: 16, color: cs.primary),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (customer.email != null) customer.email!,
                        if (customer.phoneNumber != null) customer.phoneNumber!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    if (customer.status != null) ...[
                      const SizedBox(height: 8),
                      _MiniChip(text: customer.status!, color: cs.secondary),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.24)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _TabMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _TabMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
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

// ─── Models ──────────────────────────────────────────────────────────────────

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

String? _orNull(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// How much content an app holds, per type.
class AppContentSummary {
  final int aupId;
  final String appName;
  final String slug;
  final String ownerName;
  final String ownerEmail;
  final int items;
  final int categories;
  final int customers;
  final int shops;
  final int orders;

  AppContentSummary({
    required this.aupId,
    required this.appName,
    required this.slug,
    required this.ownerName,
    required this.ownerEmail,
    required this.items,
    required this.categories,
    required this.customers,
    required this.shops,
    required this.orders,
  });

  factory AppContentSummary.fromJson(Map<String, dynamic> j) => AppContentSummary(
        aupId: _asInt(j['aupId']),
        appName: (j['appName'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        ownerName: (j['ownerName'] ?? '').toString(),
        ownerEmail: (j['ownerEmail'] ?? '').toString(),
        items: _asInt(j['items']),
        categories: _asInt(j['categories']),
        customers: _asInt(j['customers']),
        shops: _asInt(j['shops']),
        orders: _asInt(j['orders']),
      );
}

/// One catalogue entry inside an app.
class AppItemRow {
  final int id;
  final String name;
  final String? sku;
  final String? type;
  final String? status;
  final String? price;
  final String? salePrice;
  final int? stock;
  final String? shopName;

  AppItemRow({
    required this.id,
    required this.name,
    required this.sku,
    required this.type,
    required this.status,
    required this.price,
    required this.salePrice,
    required this.stock,
    required this.shopName,
  });

  factory AppItemRow.fromJson(Map<String, dynamic> j) => AppItemRow(
        id: _asInt(j['id']),
        name: (j['name'] ?? '').toString(),
        sku: _orNull(j['sku']),
        type: _orNull(j['type']),
        status: _orNull(j['status']),
        price: _orNull(j['price']),
        salePrice: _orNull(j['salePrice']),
        stock: j['stock'] == null ? null : _asInt(j['stock']),
        shopName: _orNull(j['shopName']),
      );
}

/// One end user of an app.
class AppCustomerRow {
  final int id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? status;
  final bool? verified;

  AppCustomerRow({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.status,
    required this.verified,
  });

  factory AppCustomerRow.fromJson(Map<String, dynamic> j) => AppCustomerRow(
        id: _asInt(j['id']),
        name: (j['name'] ?? '').toString(),
        email: _orNull(j['email']),
        phoneNumber: _orNull(j['phoneNumber']),
        status: _orNull(j['status']),
        verified: j['verified'] is bool ? j['verified'] as bool : null,
      );
}
