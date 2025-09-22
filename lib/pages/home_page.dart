import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:huella/login.dart';
import 'package:huella/pages/trip_detail_page.dart';
import '../models/trip_models.dart';
import 'new_trip_page.dart';
import 'new_traveller_page.dart';
import 'package:shimmer_animation/shimmer_animation.dart'; // use your version
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_models.dart';
import 'trip_detail_page.dart';
import 'traveller_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🔎 Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: _tabIndex == 0 ? 'Search trips...' : 'Search travellers...',
                          hintStyle: const TextStyle(color: Colors.black38),
                          border: InputBorder.none,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),

                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onSelected: (value) async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return; // Safety check

                    if (value == 'account') {
                      // Show account info popup
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Account Info', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.account_circle, size: 50, color: Colors.blueAccent),
                              const SizedBox(height: 12),
                              Text(user.displayName ?? "No Name", style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(user.email ?? "No Email", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    } else if (value == 'signout') {
                      // Confirm signout
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: Text('Are you sure you want to sign out from ${user.email ?? "your account"}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        }
                      }
                    } else if (value == 'rating') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thanks for rating Huella!')),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    // Non-clickable user email at top
                    PopupMenuItem<String>(
                      enabled: false,
                      child: ListTile(
                        leading: const Icon(Icons.email, color: Colors.black54),
                        title: Text(FirebaseAuth.instance.currentUser?.email ?? '', style: const TextStyle(color: Colors.black87)),
                        dense: true,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'account', child: Text('Account', style: TextStyle(fontWeight: FontWeight.w500))),
                    const PopupMenuItem(value: 'signout', child: Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red))),
                    const PopupMenuItem(value: 'rating', child: Text('Rate App', style: TextStyle(fontWeight: FontWeight.w500))),
                  ],
                ),

                ],
                ),
              ),
            ),

            // 📌 Body content
            Expanded(
              child: _tabIndex == 0
                  ? TripsTab(query: _query)
                  : TravellersTab(query: _query),
            ),
          ],
        ),
      ),

      // ➕ FAB for Trip / Traveller
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_tabIndex == 0) {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NewTripPage()),
            );
            if (result != null) setState(() {});
          } else {
            final result = await Navigator.of(context).push<Traveller>(
              MaterialPageRoute(builder: (_) => const NewTravellerPage()),
            );
            if (result != null) setState(() {});
          }
        },
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 30),
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 6,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black38,
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Travellers'),
        ],
      ),
    );
  }
}

// ---------------- Trips Tab ----------------


// ---------------- Trips Tab ----------------
class TripsTab extends StatefulWidget {
  final String query;
  const TripsTab({required this.query});

  @override
  State<TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<TripsTab> {
  Set<String> selectedTripIds = {};
  bool selectionMode = false;

  void toggleSelection(String tripId) {
    setState(() {
      if (selectedTripIds.contains(tripId)) {
        selectedTripIds.remove(tripId);
        if (selectedTripIds.isEmpty) selectionMode = false;
      } else {
        selectedTripIds.add(tripId);
        selectionMode = true;
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (selectionMode) {
      setState(() {
        selectedTripIds.clear();
        selectionMode = false;
      });
      return false; // prevent popping
    }
    return true;
  }

  Future<void> _refresh() async {
    // Trigger rebuild; Firestore stream auto-updates
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Column(
        children: [
          if (selectionMode)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text('${selectedTripIds.length} selected',
                      style: const TextStyle(color: Colors.black, fontSize: 18)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.black),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Trips?'),
                          content: Text(
                              'Are you sure you want to delete ${selectedTripIds.length} trip(s)?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        for (var id in selectedTripIds) {
                          await FirebaseFirestore.instance.collection('trips').doc(id).delete();
                        }
                        setState(() {
                          selectedTripIds.clear();
                          selectionMode = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Trips deleted successfully')),
                          );
                        }
                      }
                    },
                  )
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("trips").orderBy("startTime").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    // Shimmer grid placeholders
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: 6,
                      itemBuilder: (_, __) => Shimmer(
                        duration: const Duration(seconds: 2),
                        interval: const Duration(seconds: 0),
                        color: Colors.grey.shade300,
                        colorOpacity: 0.3,
                        enabled: true,
                        direction: ShimmerDirection.fromLTRB(),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Container(color: Colors.grey[200]),
                        ),
                      ),
                    );
                  }
                  DateTime parseDate(dynamic value) {
                    if (value == null) return DateTime.now();
                    if (value is Timestamp) return value.toDate();
                    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
                    return DateTime.now();
                  }

                  final trips = snapshot.data!.docs
                      .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (!data['title']
                        .toString()
                        .toLowerCase()
                        .contains(widget.query.toLowerCase())) return null;
                    return Trip(
                      id: doc.id,
                      title: data['title'] ?? '',
                      subtitle: data['subtitle'] ?? '',
                      origin: data['origin'] ?? '',
                      destination: data['destination'] ?? '',
                      startTime: parseDate(data['startTime']),
                      endTime: parseDate(data['endTime']),
                      transportMode: data['transportMode'] ?? '',
                      notes: data['notes'] ?? '',
                      coverImagePath: data['coverImagePath'],
                      travellerIds: List<String>.from(data['travellerIds'] ?? []), // ✅ use saved travellerIds
                    );
                  })
                      .whereType<Trip>()
                      .toList();

                  if (trips.isEmpty) {
                    return const Center(
                      child: Text('No trips yet. Tap + to create.',
                          style: TextStyle(color: Colors.black54, fontSize: 16)),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final isSelected = selectedTripIds.contains(trip.id);

                      return GestureDetector(
                        onTap: () {
                          if (selectionMode) {
                            toggleSelection(trip.id);
                          } else {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => TripDetailPage(trip: trip)));
                          }
                        },
                        onLongPress: () => toggleSelection(trip.id),
                        child: Stack(
                          children: [
                            TripCard(trip: trip),
                            if (isSelected)
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(Icons.check_circle, color: Colors.blueAccent),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Travellers Tab ----------------
class TravellersTab extends StatefulWidget {
  final String query;
  const TravellersTab({required this.query});

  @override
  State<TravellersTab> createState() => _TravellersTabState();
}

class _TravellersTabState extends State<TravellersTab> {
  Set<String> selectedTravellerIds = {};
  bool selectionMode = false;

  void toggleSelection(String travellerId) {
    setState(() {
      if (selectedTravellerIds.contains(travellerId)) {
        selectedTravellerIds.remove(travellerId);
        if (selectedTravellerIds.isEmpty) selectionMode = false;
      } else {
        selectedTravellerIds.add(travellerId);
        selectionMode = true;
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (selectionMode) {
      setState(() {
        selectedTravellerIds.clear();
        selectionMode = false;
      });
      return false; // prevent back navigation
    }
    return true;
  }

  Future<void> _refresh() async {
    setState(() {}); // rebuild to refresh
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Column(
        children: [
          // Top bar for multi-selection
          if (selectionMode)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text('${selectedTravellerIds.length} selected',
                      style: const TextStyle(color: Colors.black, fontSize: 18)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.black),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Travellers?'),
                          content: Text(
                              'Are you sure you want to delete ${selectedTravellerIds.length} traveller(s)?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete')),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        for (var id in selectedTravellerIds) {
                          await FirebaseFirestore.instance
                              .collection('travellers')
                              .doc(id)
                              .delete();
                        }
                        setState(() {
                          selectedTravellerIds.clear();
                          selectionMode = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Travellers deleted successfully')),
                          );
                        }
                      }
                    },
                  )
                ],
              ),
            ),

          // Travellers list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("travellers").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    // Shimmer placeholders
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 6,
                      itemBuilder: (_, __) => Shimmer(
                        duration: const Duration(seconds: 2),
                        interval: const Duration(seconds: 0),
                        color: Colors.grey.shade300,
                        colorOpacity: 0.3,
                        enabled: true,
                        direction: ShimmerDirection.fromLTRB(),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.grey[300]),
                            title: Container(height: 12, color: Colors.grey[300]),
                            subtitle: Container(height: 10, color: Colors.grey[200]),
                          ),
                        ),
                      ),
                    );
                  }

                  final travellers = snapshot.data!.docs
                      .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (!data['name'].toString().toLowerCase().contains(widget.query.toLowerCase())) {
                      return null;
                    }
                    return Traveller(
                      id: doc.id,
                      name: data['name'] ?? '',
                      contact: data['contact'],
                    );
                  })
                      .whereType<Traveller>()
                      .toList();

                  if (travellers.isEmpty) {
                    return const Center(
                      child: Text('No travellers added yet.',
                          style: TextStyle(color: Colors.black54, fontSize: 16)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: travellers.length,
                    itemBuilder: (context, i) {
                      final t = travellers[i];
                      final isSelected = selectedTravellerIds.contains(t.id);

                      return GestureDetector(
                        onTap: () {
                          if (selectionMode) {
                            toggleSelection(t.id);
                          } else {
                            // Navigate to traveller details
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => TravellerDetailPage(traveller: t)),
                            );
                          }
                        },
                        onLongPress: () => toggleSelection(t.id),
                        child: Stack(
                          children: [
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.black,
                                  child: Text(
                                    t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(t.name, style: const TextStyle(color: Colors.black)),
                                subtitle: Text(t.contact ?? '', style: const TextStyle(color: Colors.black54)),
                              ),
                            ),
                            if (isSelected)
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(Icons.check_circle, color: Colors.blueAccent),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}




class TripCard extends StatelessWidget {
  final Trip trip;
  const TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    print("DEBUG: trip.coverImagePath = '${trip.coverImagePath}'");

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Cover image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: trip.coverImagePath != null && trip.coverImagePath!.isNotEmpty
                ? Image.network(
              trip.coverImagePath!,   // contains https://i.ibb.co/wNxvDJtV/d44d12b34b8f.jpg
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 120,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 50, color: Colors.black26),
                  ),
                );
              },
            )
                : Container(
              height: 120,
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.landscape, color: Colors.black26, size: 50),
              ),
            ),
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  trip.subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.flag, size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${trip.origin} → ${trip.destination}',
                        style: const TextStyle(color: Colors.black87, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

