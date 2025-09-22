import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/trip_models.dart';
import 'trip_detail_page.dart';

// --- Constants ---
const double kDefaultPadding = 16.0;
const double kSmallPadding = 8.0;
const double kLargePadding = 24.0;
const double kAvatarRadius = 36.0;

class TravellerDetailPage extends StatefulWidget {
  final Traveller traveller;
  const TravellerDetailPage({required this.traveller, super.key});

  @override
  State<TravellerDetailPage> createState() => _TravellerDetailPageState();
}

class _TravellerDetailPageState extends State<TravellerDetailPage> {
  bool _isLoading = true;
  List<Trip> _travelledTrips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('travellerIds', arrayContains: widget.traveller.id)
          .get(); // removed orderBy to avoid index requirement

      final trips = snapshot.docs.map((doc) {
        final data = doc.data();
        final startTime = (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now();
        final endTime = (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now();

        return Trip(
          id: doc.id,
          title: data['title'] ?? '',
          subtitle: data['subtitle'] ?? '',
          origin: data['origin'] ?? '',
          destination: data['destination'] ?? '',
          startTime: startTime,
          endTime: endTime,
          transportMode: data['transportMode'] ?? '',
          notes: data['notes'] ?? '',
          coverImagePath: data['coverImageUrl'],
          travellerIds: List<String>.from(data['travellerIds'] ?? []),
        );
      }).toList();

      // Sort locally by startTime
      trips.sort((a, b) => a.startTime.compareTo(b.startTime));

      setState(() {
        _travelledTrips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to load trips. Please try again.');
    }
  }

  Future<void> _deleteTraveller() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Traveller?'),
        content: const Text(
            'Are you sure you want to permanently delete this traveller? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('travellers')
            .doc(widget.traveller.id)
            .delete();
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar('Traveller deleted successfully.');
        }
      } catch (e) {
        _showSnackBar('Failed to delete traveller. Please try again.');
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.traveller.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTraveller,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileInfo(),
            const SizedBox(height: kLargePadding),
            const Text(
              'Travelled Places',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: kSmallPadding),
            _buildTripsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: kAvatarRadius,
          backgroundColor: Colors.black,
          child: Text(
            widget.traveller.name.isNotEmpty
                ? widget.traveller.name[0].toUpperCase()
                : '?',
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        const SizedBox(width: kDefaultPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.traveller.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: kSmallPadding),
              Text(
                widget.traveller.contact ?? 'No contact information',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripsList() {
    if (_travelledTrips.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: kLargePadding),
          child: Text(
            'This traveller has not recorded any trips yet.',
            style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Column(
      children: _travelledTrips.map((trip) => _buildTripCard(trip)).toList(),
    );
  }

  Widget _buildTripCard(Trip trip) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TripDetailPage(trip: trip)),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: kSmallPadding),
        child: ListTile(
          leading: SizedBox(
            width: 60,
            height: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: trip.coverImagePath != null && trip.coverImagePath!.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: trip.coverImagePath!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                const Icon(Icons.image, color: Colors.black26),
                errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image, color: Colors.red),
              )
                  : const Icon(Icons.landscape, size: 50, color: Colors.black26),
            ),
          ),
          title: Text(trip.title),
          subtitle: Text('${trip.origin} → ${trip.destination}'),
        ),
      ),
    );
  }
}
