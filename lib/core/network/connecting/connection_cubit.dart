import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../server_status_controller.dart';
import 'connection_status.dart';

class ConnectionStateModel {
  final ConnectionStatus status;
  final String? message;

  const ConnectionStateModel({required this.status, this.message});

  ConnectionStateModel copyWith({ConnectionStatus? status, String? message}) {
    return ConnectionStateModel(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

/// Drives the connection banner.
///
/// Two independent signals feed it, and neither one polls:
///
///  * the device's own connectivity stream, for "no internet";
///  * [ServerStatusController], for "server unreachable". That controller is
///    fed by [GlobalErrorInterceptor] off the requests the app already makes,
///    so a reachable server proves itself through ordinary traffic.
///
/// This used to run its own heartbeat, an unauthenticated GET on the API root
/// every 8 seconds. The API answers it with 401, which the browser logs as a
/// failed request — roughly 450 red console lines an hour per open tab, plus
/// the matching load on the server, to learn what the traffic already told us.
class ConnectionCubit extends Cubit<ConnectionStateModel> {
  final Connectivity _connectivity;

  StreamSubscription? _subscription;

  //  new: delay before showing "serverDown"
  static const Duration serverDownDelay = Duration(seconds: 2);
  DateTime? _downSince;
  Timer? _downTimer;
  String? _downMessage;

  ConnectionCubit({
    Connectivity? connectivity,
  })  : _connectivity = connectivity ?? Connectivity(),
        super(const ConnectionStateModel(status: ConnectionStatus.online)) {
    _init();
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    _updateFromResults(results);

    _subscription = _connectivity.onConnectivityChanged.listen((_) async {
      final r = await _connectivity.checkConnectivity();
      _updateFromResults(r);
    });

    ServerStatusController.status.addListener(_onServerStatusChanged);
  }

  void _onServerStatusChanged() {
    if (state.status == ConnectionStatus.offline) return;

    switch (ServerStatusController.status.value) {
      case ServerUiStatus.ok:
        _clearServerDownDelay();
        if (state.status != ConnectionStatus.online) {
          emit(const ConnectionStateModel(status: ConnectionStatus.online));
        }
      case ServerUiStatus.waiting:
      case ServerUiStatus.down:
        _armServerDownDelay('Connecting… (server unreachable)');
    }
  }

  void _updateFromResults(List<ConnectivityResult> results) {
    final hasNetwork =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (!hasNetwork) {
      _clearServerDownDelay();
      emit(const ConnectionStateModel(
        status: ConnectionStatus.offline,
        message: 'No internet connection',
      ));
      return;
    }

    // Internet is back. Probe once so a server that recovered while we were
    // offline clears the banner without waiting for the next user action.
    if (state.status == ConnectionStatus.offline) {
      emit(const ConnectionStateModel(status: ConnectionStatus.online));
      unawaited(ServerStatusController.checkNow());
    }
  }

  void _armServerDownDelay([String? message]) {
    if (state.status == ConnectionStatus.offline) return;
    if (state.status == ConnectionStatus.serverDown) return;

    _downMessage = message ?? 'Connecting… (server unreachable)';
    _downSince ??= DateTime.now();

    // already armed
    if (_downTimer != null) return;

    final elapsed = DateTime.now().difference(_downSince!);
    final remaining = serverDownDelay - elapsed;

    if (remaining <= Duration.zero) {
      emit(ConnectionStateModel(
        status: ConnectionStatus.serverDown,
        message: _downMessage,
      ));
      _downTimer?.cancel();
      _downTimer = null;
      return;
    }

    _downTimer = Timer(remaining, () {
      // still down? only then emit
      if (_downSince != null && state.status != ConnectionStatus.offline) {
        emit(ConnectionStateModel(
          status: ConnectionStatus.serverDown,
          message: _downMessage,
        ));
      }
      _downTimer = null;
    });
  }

  void _clearServerDownDelay() {
    _downSince = null;
    _downMessage = null;
    _downTimer?.cancel();
    _downTimer = null;
  }

  // Optional: let Dio errors force the state (also debounced)
  void setServerDown([String? message]) {
    if (state.status == ConnectionStatus.offline) return;
    _armServerDownDelay(message);
  }

  void setOnline() {
    _clearServerDownDelay();
    emit(const ConnectionStateModel(status: ConnectionStatus.online));
  }

  @override
  Future<void> close() async {
    ServerStatusController.status.removeListener(_onServerStatusChanged);
    await _subscription?.cancel();
    _clearServerDownDelay();
    return super.close();
  }
}