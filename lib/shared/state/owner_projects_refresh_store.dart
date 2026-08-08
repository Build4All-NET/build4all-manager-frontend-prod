import 'package:flutter/foundation.dart';

/// Nudges the owner's app list to reload when something outside the list
/// changes it — submitting an app request, for one.
///
/// The list screen cannot refresh itself on navigation: the owner nav shell
/// builds its four tab screens once and keeps them mounted in an IndexedStack,
/// so returning to the tab does not re-run initState. Without this signal the
/// list keeps showing what it fetched when the shell first mounted, and only a
/// full page reload brings a newly created app into view.
class OwnerProjectsRefreshStore {
  OwnerProjectsRefreshStore._();

  static final OwnerProjectsRefreshStore I = OwnerProjectsRefreshStore._();

  /// Incremented on every request; listeners refetch when it changes.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  void requestRefresh() => revision.value++;
}
