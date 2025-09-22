import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../services/tracking_service.dart';
import '../services/storage_service.dart';

class TrackingPage extends StatefulWidget {
  final TrackingService trackingService;
  final StorageService storageService;
  const TrackingPage({super.key, required this.trackingService, required this.storageService});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final TextEditingController _taskNameController = TextEditingController(text: 'Trip');
  StreamSubscription<ActiveTaskState?>? _sub;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _sub = widget.trackingService.stream.listen((state) {
      if (mounted) setState(() {});
      if (state != null && state.positions.isNotEmpty && _mapController != null) {
        final last = state.positions.last;
        _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(last.latitude, last.longitude)));
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _taskNameController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Set<Polyline> _buildPolylines(ActiveTaskState state) {
    if (state.positions.length < 2) return {};
    final points = state.positions.map((p) => LatLng(p.latitude, p.longitude)).toList();
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.indigo,
        width: 5,
        points: points,
      )
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.trackingService.state;
    final dateStr = DateFormat('MMM d, h:mm a').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Task Tracking')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _taskNameController,
                  decoration: const InputDecoration(
                    labelText: 'Task name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_run),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: state == null ? () => widget.trackingService.start(_taskNameController.text.trim().isEmpty ? 'Trip' : _taskNameController.text.trim()) : null,
                child: const Text('Start'),
              ),
            ]),
          ),
          if (state != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Task: ${state.taskName}', style: Theme.of(context).textTheme.titleMedium),
                  Text('Started: ${DateFormat('h:mm a').format(state.startTime)} ($dateStr)'),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Elapsed: ${_formatDuration(state.elapsed)}'),
                  Text('Distance: ${(state.distanceMeters / 1000).toStringAsFixed(2)} km'),
                ])
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state == null
                ? const Center(child: Text('Start a task to see the map and live tracking'))
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: state.positions.isNotEmpty
                          ? LatLng(state.positions.last.latitude, state.positions.last.longitude)
                          : const LatLng(10.0, 76.0),
                      zoom: 15,
                    ),
                    polylines: _buildPolylines(state),
                    myLocationEnabled: true,
                    onMapCreated: (c) => _mapController = c,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: state == null ? null : (state.isPaused ? widget.trackingService.resume : widget.trackingService.pause),
                  icon: Icon(state?.isPaused == true ? Icons.play_arrow : Icons.pause),
                  label: Text(state?.isPaused == true ? 'Resume' : 'Pause'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: state == null
                      ? null
                      : () {
                          final finished = widget.trackingService.stop();
                          if (finished != null) {
                            widget.storageService.addTimeAndDistance(finished.elapsed, finished.distanceMeters);
                          }
                          if (mounted) Navigator.of(context).pop();
                        },
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}


