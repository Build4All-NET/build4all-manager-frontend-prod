import 'dart:async';

import 'package:build4all_manager/core/events/app_events.dart';
import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/superadmin/dashboard/data/services/licensing_api.dart';
import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/projects_screen.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/dashboard_repository_impl.dart';
import '../../data/services/superadmin_dashboard_api.dart';
import 'builds_screen.dart';
import 'owners_screen.dart';
import 'upgrade_requests_screen.dart';
import 'apps_licenses_screen.dart';
import '../../../publish_admin/presentation/screens/publish_requests_screen.dart';
import '../../data/services/project_api.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/header_hero.dart';
import '../widgets/pro_kpi_card.dart';
import '../widgets/pro_project_tile.dart';

class DashboardScreen extends StatelessWidget {
  final Dio? dio;

  const DashboardScreen({
    super.key,
    this.dio,
  });

  @override
  Widget build(BuildContext context) {
    final Dio resolvedDio = dio ?? DioClient.ensure();

    return BlocProvider(
      create: (_) => DashboardBloc(
        DashboardRepositoryImpl(
          ProjectApi(resolvedDio),
          LicensingApi(resolvedDio),
          SuperAdminDashboardApi(resolvedDio),
        ),
      )..add(LoadDashboard()),
      child: const _DashboardContent(),
    );
  }
}

/// CONTENT ONLY
class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  StreamSubscription<void>? _projectsSub;

  @override
  void initState() {
    super.initState();

    // This screen stays mounted in the shell's IndexedStack, so creating a
    // project on another tab would otherwise leave these counts and the
    // recent-projects list stale until a full page reload.
    _projectsSub = AppEvents.projectsChanged.listen((_) {
      if (!mounted) return;
      context.read<DashboardBloc>().add(RefreshDashboard());
    });
  }

  @override
  void dispose() {
    _projectsSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final bloc = context.read<DashboardBloc>();
    bloc.add(RefreshDashboard());

    try {
      // Hold the pull-to-refresh spinner until the data actually lands.
      // Returning immediately made the indicator snap back while the request
      // was still in flight, which reads as "the refresh did nothing".
      await bloc.stream
          .firstWhere((s) => !s.loading)
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      // Bloc closed or the request stalled — release the indicator anyway.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state.overview == null) {
          if (state.error != null) {
            return _FullPageError(
              message: state.error!,
              onRetry: () => context.read<DashboardBloc>().add(
                    LoadDashboard(),
                  ),
            );
          }

          return const _SkeletonLoader();
        }

        final ov = state.overview!;

        return RefreshIndicator.adaptive(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // Fixed-height slot so showing/hiding the bar never shifts the
              // page. A background refresh (project created on another tab)
              // is otherwise completely invisible.
              SizedBox(
                height: 2,
                child: state.loading
                    ? const LinearProgressIndicator(minHeight: 2)
                    : null,
              ),
              const SizedBox(height: 10),

              const _HeroBox(),
              const SizedBox(height: 14),

              // ── Projects ────────────────────────────────────────────
              _StatSection(
                title: l10n.dash_section_projects,
                cards: [
                  ProKpiCard(
                    icon: Icons.folder_copy_rounded,
                    label: l10n.dash_total_projects,
                    value: ov.totalProjects,
                    gradient: _g(context).primary,
                    delayMs: 0,
                    onTap: () => _open(context, const ProjectsScreen()),
                  ),
                  ProKpiCard(
                    icon: Icons.check_circle_rounded,
                    label: l10n.dash_active_projects,
                    value: ov.activeProjects,
                    gradient: _g(context).success,
                    delayMs: 70,
                    onTap: () => _open(context, const ProjectsScreen()),
                  ),
                  ProKpiCard(
                    icon: Icons.pause_circle_filled_rounded,
                    label: l10n.dash_inactive_projects,
                    value: ov.inactiveProjects,
                    gradient: _g(context).warning,
                    delayMs: 140,
                    onTap: () => _open(context, const ProjectsScreen()),
                  ),
                ],
              ),

              // The platform groups come from a newer endpoint; an older
              // backend simply does not render them.
              if (ov.hasPlatformStats) ...[
                const SizedBox(height: 14),

                // ── Apps & owners ─────────────────────────────────────
                _StatSection(
                  title: l10n.dash_section_apps,
                  cards: [
                    ProKpiCard(
                      icon: Icons.apps_rounded,
                      label: l10n.dash_total_apps,
                      value: ov.apps.total,
                      gradient: _g(context).primary,
                      onTap: () => _open(context, const AppsLicensesScreen()),
                    ),
                    ProKpiCard(
                      icon: Icons.rocket_launch_rounded,
                      label: l10n.dash_active_apps,
                      value: ov.apps.active,
                      gradient: _g(context).success,
                      delayMs: 70,
                      onTap: () => _open(context, const AppsLicensesScreen()),
                    ),
                    ProKpiCard(
                      icon: Icons.people_alt_rounded,
                      label: l10n.dash_owners,
                      value: ov.owners.total,
                      gradient: _g(context).primary,
                      delayMs: 140,
                      onTap: () => _open(context, const SuperAdminOwnersScreen()),
                    ),
                    ProKpiCard(
                      icon: Icons.how_to_reg_rounded,
                      label: l10n.dash_owners_with_apps,
                      value: ov.owners.withApps,
                      gradient: _g(context).success,
                      delayMs: 210,
                      onTap: () => _open(context, const SuperAdminOwnersScreen()),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Builds ────────────────────────────────────────────
                _StatSection(
                  title: l10n.dash_section_builds,
                  cards: [
                    ProKpiCard(
                      icon: Icons.build_circle_rounded,
                      label: l10n.dash_builds_total,
                      value: ov.builds.total,
                      gradient: _g(context).primary,
                      onTap: () => _open(context, const SuperAdminBuildsScreen()),
                    ),
                    ProKpiCard(
                      icon: Icons.autorenew_rounded,
                      label: l10n.dash_builds_in_flight,
                      value: ov.builds.inFlight,
                      gradient: _g(context).warning,
                      delayMs: 70,
                      onTap: () => _open(
                        context,
                        const SuperAdminBuildsScreen(initialStatus: 'RUNNING'),
                      ),
                    ),
                    ProKpiCard(
                      icon: Icons.error_rounded,
                      label: l10n.dash_builds_failed,
                      value: ov.builds.failed,
                      gradient: _g(context).warning,
                      delayMs: 140,
                      onTap: () => _open(
                        context,
                        const SuperAdminBuildsScreen(initialStatus: 'FAILED'),
                      ),
                    ),
                    ProKpiCard(
                      icon: Icons.history_rounded,
                      label: l10n.dash_builds_last_7_days,
                      value: ov.builds.lastSevenDays,
                      gradient: _g(context).success,
                      delayMs: 210,
                      onTap: () => _open(context, const SuperAdminBuildsScreen()),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Publishing ────────────────────────────────────────
                _StatSection(
                  title: l10n.dash_section_publishing,
                  cards: [
                    ProKpiCard(
                      icon: Icons.store_rounded,
                      label: l10n.dash_published_apps,
                      value: ov.publishing.published,
                      gradient: _g(context).success,
                      onTap: () => _open(context, PublishRequestsScreen(dio: DioClient.ensure())),
                    ),
                    ProKpiCard(
                      icon: Icons.pending_actions_rounded,
                      label: l10n.dash_publish_awaiting,
                      value: ov.publishing.awaitingReview,
                      gradient: _g(context).warning,
                      delayMs: 70,
                      onTap: () => _open(context, PublishRequestsScreen(dio: DioClient.ensure())),
                    ),
                    ProKpiCard(
                      icon: Icons.outbox_rounded,
                      label: l10n.dash_publish_total,
                      value: ov.publishing.total,
                      gradient: _g(context).primary,
                      delayMs: 140,
                      onTap: () => _open(context, PublishRequestsScreen(dio: DioClient.ensure())),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Licensing ─────────────────────────────────────────
                _StatSection(
                  title: l10n.dash_section_licensing,
                  cards: [
                    ProKpiCard(
                      icon: Icons.upgrade_rounded,
                      label: l10n.dash_upgrade_requests,
                      value: ov.licensing.pendingUpgradeRequests,
                      gradient: _g(context).primary,
                      onTap: () => _open(
                        context,
                        const SuperAdminUpgradeRequestsScreen(),
                      ),
                    ),
                    ProKpiCard(
                      icon: Icons.hourglass_bottom_rounded,
                      label: l10n.dash_licenses_expiring,
                      value: ov.licensing.expiringWithin30Days,
                      gradient: _g(context).warning,
                      delayMs: 70,
                      onTap: () => _open(context, const AppsLicensesScreen()),
                    ),
                    ProKpiCard(
                      icon: Icons.block_rounded,
                      label: l10n.dash_licenses_expired,
                      value: ov.licensing.expired,
                      gradient: _g(context).warning,
                      delayMs: 140,
                      onTap: () => _open(context, const AppsLicensesScreen()),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              Text(
                l10n.dash_recent_projects,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),

              const SizedBox(height: 10),

              if (state.error != null && state.recent.isEmpty)
                _InlineError(
                  message: state.error!,
                  onRetry: () => context.read<DashboardBloc>().add(
                        LoadDashboard(),
                      ),
                ),

              Card(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                child: state.recent.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(l10n.dash_no_recent),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.recent.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          thickness: .5,
                        ),
                        itemBuilder: (_, i) => ProProjectTile(
                          project: state.recent[i],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroBox extends StatelessWidget {
  const _HeroBox();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = w < 380 ? 150.0 : 180.0;

    return SizedBox(
      height: h,
      width: double.infinity,
      child: const HeaderHero(),
    );
  }
}

class _FullPageError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FullPageError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: cs.error,
              size: 46,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.common_error,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.common_retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.error.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.error.withOpacity(.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: cs.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.common_retry),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const _HeroBox(),
        const SizedBox(height: 14),
        _shimmerBox(cs),
        const SizedBox(height: 12),
        _shimmerBox(cs),
        const SizedBox(height: 12),
        _shimmerBox(cs),
        const SizedBox(height: 14),
        _shimmerList(cs),
      ],
    );
  }

  Widget _shimmerBox(ColorScheme cs) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            cs.surfaceContainerHigh,
            cs.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _shimmerList(ColorScheme cs) {
    return Card(
      elevation: 0,
      child: Column(
        children: List.generate(
          6,
          (i) => Container(
            height: 64,
            margin: EdgeInsets.only(bottom: i == 5 ? 0 : .5),
            color: cs.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }
}

/// Opens a drill-down for a stat card.
void _open(BuildContext context, Widget screen) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

/// A titled group of KPI cards that reflows from one to four columns.
class _StatSection extends StatelessWidget {
  final String title;
  final List<Widget> cards;

  const _StatSection({required this.title, required this.cards});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width > 1180
                ? 4
                : width > 860
                    ? 3
                    : width > 560
                        ? 2
                        : 1;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: 120,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (_, i) => cards[i],
            );
          },
        ),
      ],
    );
  }
}

class _g {
  final Gradient primary;
  final Gradient success;
  final Gradient warning;

  _g._(
    this.primary,
    this.success,
    this.warning,
  );

  factory _g(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _g._(
      LinearGradient(colors: [cs.primary, cs.secondary]),
      LinearGradient(colors: [cs.primary, cs.tertiary]),
      LinearGradient(colors: [cs.secondary, cs.error]),
    );
  }
}