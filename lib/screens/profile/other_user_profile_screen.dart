import 'package:flutter/material.dart';
import 'package:sepadan/models/user_profile.dart';

class OtherUserProfileScreen extends StatelessWidget {
  final UserProfile profile;

  const OtherUserProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Gallery (Simple Horizontal Scroll)
            if (profile.photos.isNotEmpty)
              SizedBox(
                height: 400,
                child: PageView.builder(
                  itemCount: profile.photos.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      profile.photos[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  },
                ),
              )
            else
              Container(
                height: 300,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Icon(Icons.person, size: 100, color: Colors.white),
              ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${profile.name}, ${profile.age}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: profile.gender == 'male' ? Colors.blue.shade100 : Colors.pink.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          profile.gender.toUpperCase(),
                          style: TextStyle(
                            color: profile.gender == 'male' ? Colors.blue.shade800 : Colors.pink.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About Me Section
                  _buildSectionTitle(context, 'About Me'),
                  const SizedBox(height: 8),
                  Text(
                    profile.aboutMe.isNotEmpty ? profile.aboutMe : 'No description provided.',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // Faith Section
                  _buildSectionTitle(context, 'Who is Jesus Christ to me?'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.shade100),
                    ),
                    child: Text(
                      profile.faithAnswer.isNotEmpty ? profile.faithAnswer : 'No answer provided.',
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
    );
  }
}
