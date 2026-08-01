# build4all_manager

Build4All owner/manager app (Flutter — Android, iOS and web).

## Getting Started

```bash
flutter pub get
flutter run
```

## Web

### Building

```bash
./scripts/build_web.sh                       # output in build/web
./scripts/build_web.sh --base-href /manager/ # when not served from the domain root
```

The script wraps `flutter build web` with the flags that matter for cold-load
time (`--no-web-resources-cdn`, `--pwa-strategy=offline-first`,
`--tree-shake-icons`) and prints a deployment checklist when it finishes.

### Start-up behaviour

A Flutter web app cannot paint anything until `main.dart.js` and the renderer
have been downloaded and the Dart entrypoint has run. Anything the page does
before that point is what the user experiences as "the app is broken".

Three rules keep that window short and legible:

1. **`web/index.html` owns the first paint.** It renders a branded splash
   (logo, progress bar, escalating status text, and a Reload button after 25s)
   straight from HTML/CSS, with no JavaScript dependency beyond removing it.
   The splash is dismissed on the engine's `flutter-first-frame` event, with a
   `MutationObserver` on Flutter's host element as a fallback.

2. **Nothing that touches the network is awaited before `runApp()`.**
   `AppBootstrap.initLocal()` only reads shared preferences and the asset
   bundle. Firebase, push registration and local notifications run in
   `AppBootstrap.initBackgroundServices()`, started *after* `runApp()`. Code
   that needs Firebase must await `AppBootstrap.firebaseReady` first — it is no
   longer guaranteed to be ready when the first screen builds.

3. **Every start-up await is time-boxed.** A hung plugin or an unreachable
   backend degrades to "go to the login screen", never to an endless spinner.

In-app loading states use `AppLoadingView`, which mirrors the HTML splash so
the hand-off between the two reads as a single screen.

### Deploying

Serve `build/web` with compression enabled, and set cache headers so returning
users do not re-download the bundle:

| Path                                                  | `Cache-Control`                          |
| ----------------------------------------------------- | ---------------------------------------- |
| `canvaskit/*`, `assets/*`                             | `public, max-age=31536000, immutable`    |
| `index.html`, `flutter_service_worker.js`, `flutter_bootstrap.js` | `no-cache`                    |

Caching `index.html` or `flutter_service_worker.js` will pin users to an old
service worker and they will stop receiving new releases.
