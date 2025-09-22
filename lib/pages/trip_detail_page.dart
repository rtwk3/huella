import 'package:flutter/material.dart';
import '../models/trip_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class TripDetailPage extends StatefulWidget {
  final Trip trip;
  const TripDetailPage({required this.trip});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  late TextEditingController titleController;
  late TextEditingController subtitleController;
  late TextEditingController originController;
  late TextEditingController destinationController;
  late TextEditingController notesController;
  bool editMode = false;


  @override
  List<Traveller> tripTravellers = [];
  bool loadingTravellers = true;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.trip.title);
    subtitleController = TextEditingController(text: widget.trip.subtitle);
    originController = TextEditingController(text: widget.trip.origin);
    destinationController = TextEditingController(text: widget.trip.destination);
    notesController = TextEditingController(text: widget.trip.notes);

    fetchTravellers(); // fetch on page load
  }

  Future<void> fetchTravellers() async {
    if (widget.trip.travellerIds.isEmpty) {
      setState(() {
        tripTravellers = [];
        loadingTravellers = false;
      });
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('travellers')
        .where(FieldPath.documentId, whereIn: widget.trip.travellerIds)
        .get();

    final travellers = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Traveller(
        id: doc.id,
        name: data['name'] ?? '',
        contact: data['contact'],
        profileImagePath: data['profileImagePath'],
      );
    }).toList();

    setState(() {
      tripTravellers = travellers;
      loadingTravellers = false;
    });
  }



  @override
  void dispose() {
    titleController.dispose();
    subtitleController.dispose();
    originController.dispose();
    destinationController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void saveChanges() async {
    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .update({
      'title': titleController.text,
      'subtitle': subtitleController.text,
      'origin': originController.text,
      'destination': destinationController.text,
      'notes': notesController.text,
    });
    setState(() => editMode = false);
  }

  void shareTrip() {
    final formatter = DateFormat('dd MMM yyyy, HH:mm');
    final text = '''
Trip: ${titleController.text}
Subtitle: ${subtitleController.text}
From: ${originController.text} → ${destinationController.text}
Start: ${formatter.format(widget.trip.startTime)}
End: ${formatter.format(widget.trip.endTime)}
Notes: ${notesController.text}
''';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: shareTrip,
          ),
          IconButton(
            icon: Icon(editMode ? Icons.check : Icons.edit),
            onPressed: () {
              if (editMode) {
                saveChanges();
              } else {
                setState(() => editMode = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero cover image
            Container(
              height: 220,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: widget.trip.coverImagePath != null &&
                    widget.trip.coverImagePath!.isNotEmpty
                    ? Image.network(
                  widget.trip.coverImagePath!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Shimmer(
                      duration: const Duration(seconds: 2),
                      interval: const Duration(seconds: 0),
                      color: Colors.grey.shade300,
                      colorOpacity: 0.3,
                      enabled: true,
                      direction: ShimmerDirection.fromLTRB(),
                      child: Container(
                        color: Colors.grey.shade200,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            size: 80, color: Colors.white70),
                      ),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.landscape,
                        size: 80, color: Colors.white70),
                  ),
                ),
              ),
            ),


            // Info card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildField(
                    'Title',
                    Icons.title,
                    widget.trip.title,
                    editable: editMode,
                    controller: titleController,
                  ),
                  buildField(
                    'Subtitle',
                    Icons.subtitles,
                    widget.trip.subtitle,
                    editable: editMode,
                    controller: subtitleController,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: buildField(
                          'Origin',
                          Icons.flag,
                          widget.trip.origin,
                          editable: editMode,
                          controller: originController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildField(
                          'Destination',
                          Icons.location_on,
                          widget.trip.destination,
                          editable: editMode,
                          controller: destinationController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start: ${formatter.format(widget.trip.startTime)}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  Text(
                    'End: ${formatter.format(widget.trip.endTime)}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  buildField(
                    'Notes',
                    Icons.note,
                    widget.trip.notes,
                    editable: editMode,
                    controller: notesController,
                    maxLines: null, // allows the field to grow dynamically
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Travellers card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Travellers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (loadingTravellers)
                    const Center(child: CircularProgressIndicator())
                  else if (tripTravellers.isEmpty)
                    const Text('No travellers added for this trip.', style: TextStyle(color: Colors.black54))
                  else
                    Column(
                      children: tripTravellers.map((t) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: t.profileImagePath != null ? NetworkImage(t.profileImagePath!) : null,
                            backgroundColor: Colors.blueAccent,
                            child: t.profileImagePath == null
                                ? Text(t.name.isNotEmpty ? t.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white))
                                : null,
                          ),
                          title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: t.contact != null ? Text(t.contact!) : null,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),


            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget buildField(String label, IconData icon, String value, {bool editable = false, TextEditingController? controller, int? maxLines}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: editable ? Colors.white : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: editable ? Border.all(color: Colors.blueAccent, width: 2) : Border.all(color: Colors.grey.shade300),
              boxShadow: editable
                  ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                  : [],
            ),
            child: editable
                ? TextField(
              controller: controller,
              maxLines: maxLines ?? null,
              style: TextStyle(fontSize: 16, color: Colors.black87),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            )
                : Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
