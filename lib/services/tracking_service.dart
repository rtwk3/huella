import 'dart:async';
import 'package:geolocator/geolocator.dart';

class ActiveTaskState {
  final String taskName;
  final DateTime startTime;
  final Duration elapsed;
  final double distanceMeters;
  final List<Position> positions;
  final bool isPaused;

  ActiveTaskState({
    required this.taskName,
    required this.startTime,
    required this.elapsed,
    required this.distanceMeters,
    required this.positions,
    required this.isPaused,
  });

  ActiveTaskState copyWith({
    Duration? elapsed,
    double? distanceMeters,
    List<Position>? positions,
    bool? isPaused,
  }) {
    return ActiveTaskState(
      taskName: taskName,
      startTime: startTime,
      elapsed: elapsed ?? this.elapsed,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      positions: positions ?? this.positions,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}

class TrackingService {
  StreamSubscription<Position>? _positionSub;
  Timer? _timer;
  ActiveTaskState? _state;
  final StreamController<ActiveTaskState?> _controller = StreamController.broadcast();

  Stream<ActiveTaskState?> get stream => _controller.stream;
  ActiveTaskState? get state => _state;

  Future<bool> ensurePermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<void> start(String taskName) async {
    final ok = await ensurePermissions();
    if (!ok) return;
    _state = ActiveTaskState(
      taskName: taskName,
      startTime: DateTime.now(),
      elapsed: Duration.zero,
      distanceMeters: 0,
      positions: <Position>[],
      isPaused: false,
    );
    _controller.add(_state);
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen(_onPosition);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state == null || _state!.isPaused) return;
      _state = _state!.copyWith(elapsed: _state!.elapsed + const Duration(seconds: 1));
      _controller.add(_state);
    });
  }

  void _onPosition(Position position) {
    if (_state == null || _state!.isPaused) return;
    final positions = List<Position>.from(_state!.positions)..add(position);
    double distance = _state!.distanceMeters;
    if (positions.length >= 2) {
      final last = positions[positions.length - 2];
      distance += Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        position.latitude,
        position.longitude,
      );
    }
    _state = _state!.copyWith(positions: positions, distanceMeters: distance);
    _controller.add(_state);
  }

  void pause() {
    if (_state == null) return;
    _state = _state!.copyWith(isPaused: true);
    _controller.add(_state);
  }

  void resume() {
    if (_state == null) return;
    _state = _state!.copyWith(isPaused: false);
    _controller.add(_state);
  }

  ActiveTaskState? stop() {
    _positionSub?.cancel();
    _positionSub = null;
    _timer?.cancel();
    _timer = null;
    final finished = _state;
    _state = null;
    _controller.add(_state);
    return finished;
  }

  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
    _controller.close();
  }
}


