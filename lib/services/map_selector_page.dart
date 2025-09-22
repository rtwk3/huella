import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CurrentLocationPage extends StatefulWidget {
  const CurrentLocationPage({super.key});

  @override
  State<CurrentLocationPage> createState() => _CurrentLocationPageState();
}

class _CurrentLocationPageState extends State<CurrentLocationPage> {
  String? _currentAddress;
  bool _loading = false;

  Future<void> _getCurrentPlace() async {
    setState(() => _loading = true);

    try {
      // 1️⃣ Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _currentAddress = 'Location permission denied');
        return;
      }

      // 2️⃣ Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 3️⃣ Reverse geocode to get place name
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _currentAddress =
          '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        });
      } else {
        setState(() => _currentAddress = 'Unknown location');
      }
    } catch (e) {
      setState(() => _currentAddress = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Current Place')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _loading
                ? const CircularProgressIndicator()
                : Text(_currentAddress ?? 'Press the button to get location'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getCurrentPlace,
              child: const Text('Get Current Place Name'),
            )
          ],
        ),
      ),
    );
  }
}
