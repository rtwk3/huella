import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_models.dart';
import 'package:huella/services/image_upload_service.dart';

class NewTripPage extends StatefulWidget {
  const NewTripPage({super.key});
  @override
  State<NewTripPage> createState() => _NewTripPageState();
}

class _NewTripPageState extends State<NewTripPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _mode = 'Bus';
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(hours: 1));
  File? _coverImage;
  final List<Traveller> _selectedTravellers = [];

  List<Traveller> allTravellers = [];
  bool loadingTravellers = true;

  @override
  void initState() {
    super.initState();
    _loadTravellers();
  }

  Future<void> _loadTravellers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('travellers').get();
      setState(() {
        allTravellers = snapshot.docs.map((doc) {
          return Traveller(
            id: doc.id,
            name: doc['name'] ?? '',
            contact: doc['contact'],
          );
        }).toList();
        loadingTravellers = false;
      });
    } catch (e) {
      setState(() => loadingTravellers = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load travellers: $e')));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _originController.dispose();
    _destController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Uint8List? _coverImageBytes; // for web

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      if (kIsWeb) {
        _coverImageBytes = await img.readAsBytes();
      } else {
        _coverImage = File(img.path);
      }
      setState(() {});
    }
  }


  Future<void> _useCurrentAs(String which) async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    final pos = await Geolocator.getCurrentPosition();
    final value =
        '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
    setState(() {
      if (which == 'start') {
        _originController.text = value;
      } else {
        _destController.text = value;
      }
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty ||
        _originController.text.trim().isEmpty ||
        _destController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title, origin, and destination')),
      );
      return;
    }

    // Upload cover image (if any)
    String? imageUrl;
    if (kIsWeb && _coverImageBytes != null) {
      imageUrl = await ImageUploadService.uploadToImgBB(bytes: _coverImageBytes);
    } else if (!kIsWeb && _coverImage != null) {
      imageUrl = await ImageUploadService.uploadToImgBB(file: _coverImage);
    }

    if ((_coverImage != null || _coverImageBytes != null) && imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload cover image')),
      );
      return;
    }

    try {
      // Generate a new Firestore doc ID
      final docRef = FirebaseFirestore.instance.collection("trips").doc();

      // Build the Trip object
      final newTrip = Trip(
        id: docRef.id,
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        origin: _originController.text.trim(),
        destination: _destController.text.trim(),
        startTime: _start,
        endTime: _end,
        transportMode: _mode,
        notes: _notesController.text.trim(),
        coverImagePath: imageUrl,
        travellerIds: _selectedTravellers.map((t) => t.id).toList(),
      );

      // Save to Firestore
      await docRef.set(newTrip.toMap());

      if (mounted) {
        Navigator.of(context).pop(newTrip); // return the Trip object
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save trip: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Create New Trip",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loadingTravellers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image picker
            GestureDetector(
              onTap: _pickCover,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade200,
                  image: _coverImage != null
                      ? DecorationImage(
                      image: FileImage(_coverImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: _coverImage == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("Tap to add cover",
                        style: TextStyle(color: Colors.grey)),
                  ],
                )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
            _buildInput(_titleController, "Trip Title"),
            const SizedBox(height: 12),
            _buildInput(_subtitleController, "Subtitle"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildInput(_originController, "Origin",
                        icon: Icons.my_location)),
                const SizedBox(width: 8),
                IconButton(
                    onPressed: () => _useCurrentAs('start'),
                    icon: const Icon(Icons.gps_fixed))
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildInput(_destController, "Destination",
                        icon: Icons.location_on_outlined)),
                const SizedBox(width: 8),
                IconButton(
                    onPressed: () => _useCurrentAs('end'),
                    icon: const Icon(Icons.gps_fixed))
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _mode,
              decoration: InputDecoration(
                labelText: "Transport Mode",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'Bus', child: Text("Bus")),
                DropdownMenuItem(value: 'Car', child: Text("Car")),
                DropdownMenuItem(value: 'Train', child: Text("Train")),
                DropdownMenuItem(value: 'Walk', child: Text("Walk")),
                DropdownMenuItem(value: 'Other', child: Text("Other")),
              ],
              onChanged: (v) => setState(() => _mode = v ?? 'Bus'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _DateTimeField(
                        label: "Start Time",
                        value: _start,
                        onChanged: (v) => setState(() => _start = v))),
                const SizedBox(width: 12),
                Expanded(
                    child: _DateTimeField(
                        label: "End Time",
                        value: _end,
                        onChanged: (v) => setState(() => _end = v))),
              ],
            ),
            const SizedBox(height: 12),
            _buildInput(_notesController, "Notes", maxLines: 3),
            const SizedBox(height: 12),
            Text("Travellers",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: allTravellers.map((t) {
                final selected =
                _selectedTravellers.any((e) => e.id == t.id);
                return FilterChip(
                  label: Text(t.name),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedTravellers.add(t);
                      } else {
                        _selectedTravellers
                            .removeWhere((e) => e.id == t.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child:
              const Text("Create Trip", style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController c, String label,
      {int maxLines = 1, IconData? icon}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  const _DateTimeField(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (date == null) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        if (time == null) return;
        onChanged(DateTime(
            date.year, date.month, date.day, time.hour, time.minute));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
              '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
