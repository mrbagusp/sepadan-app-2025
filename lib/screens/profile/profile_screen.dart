// ============================================================
// 📁 lib/screens/profile/profile_screen.dart
// ✅ UPDATED: Clear Save button + Logout text button
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/screens/profile/profile_notifier.dart';
import 'package:sepadan/services/auth_service.dart';
import 'package:sepadan/core/app_router.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdate;

  const ProfileScreen({super.key, this.onProfileUpdate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileNotifier(),
      child: Consumer<ProfileNotifier>(
        builder: (context, notifier, child) {
          // Pass context for location dialogs
          notifier.setContext(context);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Your Profile'),
              elevation: 0,
              automaticallyImplyLeading: false,
              // 🔥 LOGOUT BUTTON - Clear text
              leading: TextButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              leadingWidth: 100,
              actions: [
                // 🔥 SAVE BUTTON - Clear text button
                if (notifier.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton.icon(
                      onPressed: () => _saveProfile(context, notifier),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            body: _buildBody(context, notifier),
          );
        },
      ),
    );
  }

  // 🔥 Extracted save logic
  Future<void> _saveProfile(BuildContext context, ProfileNotifier notifier) async {
    if (_formKey.currentState!.validate()) {
      final success = await notifier.saveData();
      if (success) {
        await markProfileComplete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Profile saved successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
          widget.onProfileUpdate?.call();
          context.go('/main');
        }
      } else if (notifier.errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(notifier.errorMessage!)),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Form validation failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Please fill all required fields'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout, color: Colors.red.shade400),
              ),
              const SizedBox(width: 12),
              const Text('Logout'),
            ],
          ),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProfileNotifier notifier) {
    if (notifier.isLoading && notifier.userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPhotoGrid(context, notifier),
          const SizedBox(height: 24),
          _buildProfileForm(context, notifier),
          const SizedBox(height: 24),
          _buildPreferencesSection(context, notifier),
          const SizedBox(height: 24),
          _buildNotificationSection(context, notifier),
          const SizedBox(height: 24),
          _buildLocationSection(context, notifier),
          const SizedBox(height: 24),
          _buildFeedbackSection(context, notifier),
          const SizedBox(height: 24),
          _buildDangerZone(context, notifier),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context, ProfileNotifier notifier) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.feedback_outlined, color: Colors.deepPurple.shade400),
                const SizedBox(width: 12),
                Text(
                  'Help & Feedback',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Found a bug? Or have a suggestion for Sepadan?',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notifier.feedbackController,
              decoration: InputDecoration(
                hintText: 'Describe your issue or suggestion here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Send to Admin'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final success = await notifier.sendFeedback();
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank you! Your feedback has been sent.'), backgroundColor: Colors.blue),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, ProfileNotifier notifier) {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.red.shade400),
                const SizedBox(width: 12),
                Text(
                  'Danger Zone',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Permanently remove your data and account'),
              trailing: Icon(Icons.delete_forever, color: Colors.red.shade400),
              onTap: () => _showDeleteConfirmDialog(context, notifier),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, ProfileNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade400),
            const SizedBox(width: 12),
            const Text('Delete Account?'),
          ],
        ),
        content: const Text('This action cannot be undone. All your matches, chats, and profile data will be lost forever.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await notifier.deleteAccount();
              if (success && context.mounted) {
                await clearProfileCache();
                context.go('/login');
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(BuildContext context, ProfileNotifier notifier) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_outlined, color: Colors.deepPurple.shade400),
                const SizedBox(width: 12),
                Text(
                  'Notification Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Daily Devotional'),
              subtitle: const Text('Setiap jam 6:00 AM WIB'),
              value: notifier.notifyDailyDevo,
              onChanged: (val) => notifier.updateNotification('dailyDevo', val),
              activeColor: Colors.deepPurple,
            ),
            SwitchListTile(
              title: const Text('New Match'),
              subtitle: const Text('Saat seseorang menyukai Anda kembali'),
              value: notifier.notifyNewMatch,
              onChanged: (val) => notifier.updateNotification('newMatch', val),
              activeColor: Colors.deepPurple,
            ),
            SwitchListTile(
              title: const Text('New Message'),
              subtitle: const Text('Pemberitahuan pesan chat masuk'),
              value: notifier.notifyNewMessage,
              onChanged: (val) => notifier.updateNotification('newMessage', val),
              activeColor: Colors.deepPurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, ProfileNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library_outlined, color: Colors.deepPurple.shade400),
            const SizedBox(width: 12),
            Text(
              'Your Photos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Upload at least 1 photo',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: 6,
          itemBuilder: (context, index) {
            if (index < notifier.images.length) {
              final image = notifier.images[index];
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: image is String
                        ? Image.network(image, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                        : Image.file(image as File, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  ),
                  if (index == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Main',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => notifier.removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  )
                ],
              );
            }
            return GestureDetector(
              onTap: () => notifier.pickImage(index),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: Colors.grey[500], size: 32),
                    const SizedBox(height: 4),
                    Text('Add', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileForm(BuildContext context, ProfileNotifier notifier) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.deepPurple.shade400),
                const SizedBox(width: 12),
                Text(
                  'About You',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: notifier.nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notifier.ageController,
              decoration: InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Age is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: notifier.gender,
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) => value != null ? notifier.gender = value : null,
              decoration: InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notifier.aboutMeController,
              decoration: InputDecoration(
                labelText: 'About Me',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 4,
              validator: (v) => v == null || v.isEmpty ? 'About Me is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notifier.faithAnswerController,
              decoration: InputDecoration(
                labelText: 'Who is Jesus Christ to you?',
                hintText: 'Required for screening purpose',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 4,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'This field is mandatory for screening purpose';
                }
                if (v.trim().length < 10) {
                  return 'Please provide a more descriptive answer';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context, ProfileNotifier notifier) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.deepPurple.shade400),
                const SizedBox(width: 12),
                Text(
                  'Your Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Show Me', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Men'),
                  selected: notifier.interestedInGender == 'male',
                  onSelected: (s) => s ? notifier.interestedInGender = 'male' : null,
                  selectedColor: Colors.deepPurple.shade100,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Women'),
                  selected: notifier.interestedInGender == 'female',
                  onSelected: (s) => s ? notifier.interestedInGender = 'female' : null,
                  selectedColor: Colors.deepPurple.shade100,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Both'),
                  selected: notifier.interestedInGender == 'both',
                  onSelected: (s) => s ? notifier.interestedInGender = 'both' : null,
                  selectedColor: Colors.deepPurple.shade100,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Age Range: ${notifier.preferredAgeRange.start.round()} - ${notifier.preferredAgeRange.end.round()}'),
            RangeSlider(
              values: notifier.preferredAgeRange,
              min: 18,
              max: 100,
              divisions: 82,
              labels: RangeLabels(
                notifier.preferredAgeRange.start.round().toString(),
                notifier.preferredAgeRange.end.round().toString(),
              ),
              activeColor: Colors.deepPurple,
              onChanged: (v) => notifier.preferredAgeRange = v,
            ),
            const SizedBox(height: 16),
            Text('Max Distance: ${notifier.preferredDistance.round()} km'),
            Slider(
              value: notifier.preferredDistance,
              min: 1,
              max: 500,
              divisions: 499,
              label: '${notifier.preferredDistance.round()} km',
              activeColor: Colors.deepPurple,
              onChanged: (v) => notifier.preferredDistance = v,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context, ProfileNotifier notifier) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.location_on_outlined, color: Colors.deepPurple.shade400, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notifier.location != null ? 'Location Updated ✓' : 'Location Not Set',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: notifier.location != null ? Colors.green : Colors.orange,
                    ),
                  ),
                  Text(
                    'Diperlukan untuk matching',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                await notifier.updateLocation();
                if (notifier.errorMessage != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notifier.errorMessage!), backgroundColor: Colors.red));
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location Updated Successfully!"), backgroundColor: Colors.green));
                }
              },
              child: const Text('UPDATE'),
            ),
          ],
        ),
      ),
    );
  }
}