import 'dart:async';

/// App-wide announcements for data that more than one screen displays.
///
/// Both shells keep every visited tab mounted inside an `IndexedStack`, which
/// is what makes tab switching instant — but it also means a screen that
/// loaded its data in `initState` never notices a change made from another
/// tab. Creating a project on the "Create project" tab left the dashboard
/// showing its stale list until the whole page was reloaded.
///
/// Reloading on every tab switch would trade that bug for constant refetching.
/// Instead, whoever changes the data announces it here, and the screens that
/// display it reload exactly then.
class AppEvents {
  AppEvents._();

  static final StreamController<void> _projectsChanged =
      StreamController<void>.broadcast();

  /// Fires whenever a project is created, edited, enabled, disabled or
  /// archived — anything that makes a project list or count out of date.
  static Stream<void> get projectsChanged => _projectsChanged.stream;

  static void notifyProjectsChanged() {
    if (!_projectsChanged.isClosed) {
      _projectsChanged.add(null);
    }
  }
}
