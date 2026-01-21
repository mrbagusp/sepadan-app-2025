import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/daily_devo.dart';
import '../../models/prayer_request.dart';
import '../../models/event.dart';
import '../../models/testimonial.dart';
import '../admin/admin_screen.dart'; // Import admin screen

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community Hub'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daily Devo'),
              Tab(text: 'Prayer Requests'),
              Tab(text: 'Events'),
              Tab(text: 'Testimonials'),
            ],
          ),
          actions: [
            if (user != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data!.exists &&
                      (snapshot.data!.data() as Map<String, dynamic>)['isAdmin'] == true) {
                    return IconButton(
                      icon: const Icon(Icons.admin_panel_settings),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminScreen()),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildDailyDevoList(user),
            _buildPrayerRequestList(user),
            _buildEventList(user),
            _buildTestimonialList(user),
          ],
        ),
        floatingActionButton: user != null
            ? StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data!.exists &&
                      (snapshot.data!.data() as Map<String, dynamic>)['isPremium'] == true) {
                    return FloatingActionButton(
                      onPressed: () {
                        // TODO: Navigate to the appropriate form
                      },
                      child: const Icon(Icons.add),
                    );
                  }
                  return FloatingActionButton(
                    onPressed: () {
                      // TODO: Navigate to the premium subscription page
                    },
                    child: const Icon(Icons.add),
                  );
                },
              )
            : null,
      ),
    );
  }

  Widget _buildDailyDevoList(User? user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('daily_devos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final devo = DailyDevo.fromFirestore(snapshot.data!.docs[index]);
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(devo.title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8.0),
                    Text(devo.author, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8.0),
                    StreamBuilder<DocumentSnapshot>(
                      stream: user != null
                          ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .snapshots()
                          : null,
                      builder: (context, userSnapshot) {
                        final bool isPremium = userSnapshot.hasData &&
                            userSnapshot.data!.exists &&
                            (userSnapshot.data!.data() as Map<String, dynamic>)['isPremium'] == true;
                        final content = isPremium || devo.content.length <= 200
                            ? devo.content
                            : '${devo.content.substring(0, 200)}...';

                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: [
                                Colors.black,
                                if (!isPremium && devo.content.length > 200)
                                  Colors.transparent
                                else
                                  Colors.black
                              ],
                              stops: const [0.5, 1.0],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: Text(content),
                        );
                      },
                    ),
                    if (user != null)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData &&
                              snapshot.data!.exists &&
                              (snapshot.data!.data() as Map<String, dynamic>)['isPremium'] == false) {
                            return ElevatedButton(
                              onPressed: () {
                                // TODO: Navigate to the premium subscription page
                              },
                              child: const Text('Read More (Upgrade to Premium)'),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrayerRequestList(User? user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('prayer_requests').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final request = PrayerRequest.fromFirestore(snapshot.data!.docs[index]);
            return ListTile(
              title: Text(request.title),
              subtitle: Text(request.details),
            );
          },
        );
      },
    );
  }

  Widget _buildEventList(User? user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final event = Event.fromFirestore(snapshot.data!.docs[index]);
            return ListTile(
              title: Text(event.title),
              subtitle: Text(event.location),
            );
          },
        );
      },
    );
  }

  Widget _buildTestimonialList(User? user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('testimonials').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final testimonial = Testimonial.fromFirestore(snapshot.data!.docs[index]);
            return ListTile(
              title: Text(testimonial.uid),
              subtitle: Text(testimonial.story),
            );
          },
        );
      },
    );
  }
}
