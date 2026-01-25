import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/screens/profile/profile_notifier.dart';
import 'package:sepadan/services/auth_service.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onProfileUpdate;

  const ProfileScreen({super.key, this.onProfileUpdate});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileNotifier(),
      child: Consumer<ProfileNotifier>(
        builder: (context, notifier, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Your Profile'),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () => _showLogoutDialog(context),
              ),
              actions: [
                if (notifier.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 20.0),
                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: 'Save Profile & Preferences',
                    onPressed: () async {
                      final success = await notifier.saveData();
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile & Preferences Saved Successfully!'), backgroundColor: Colors.green),
                        );
                        onProfileUpdate?.call();
                      } else if (notifier.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(notifier.errorMessage!), backgroundColor: Colors.red),
                        );
                      }
                    },
                  ),
              ],
            ),
            body: _buildBody(context, notifier),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pop(context); // Tutup dialog
                  context.go('/login'); // Kembali ke halaman login
                }
              },
              child: const Text('Keluar', style: TextStyle(color: Colors.red)),
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

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildPhotoGrid(context, notifier),
        const SizedBox(height: 24),
        _buildProfileForm(context, notifier),
        const SizedBox(height: 24),
        _buildPreferencesSection(context, notifier),
        const SizedBox(height: 24),
        _buildLocationSection(context, notifier),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildPhotoGrid(BuildContext context, ProfileNotifier notifier) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
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
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => notifier.removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54, 
                      shape: BoxShape.circle, // Memperbaiki CircleBorder() menjadi BoxShape.circle
                    ),
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
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 40),
          ),
        );
      },
    );
  }

  Widget _buildProfileForm(BuildContext context, ProfileNotifier notifier) {
     return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
              'About You',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
          TextFormField(
            controller: notifier.nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: notifier.ageController,
            decoration: const InputDecoration(labelText: 'Age'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: notifier.gender,
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'female', child: Text('Female')),
            ],
            onChanged: (value) {
              if (value != null) {
                notifier.gender = value;
              }
            },
            decoration: const InputDecoration(labelText: 'Gender'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: notifier.aboutMeController,
            decoration: const InputDecoration(labelText: 'About Me'),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: notifier.faithAnswerController,
            decoration: const InputDecoration(labelText: 'Who is Jesus Christ to you?'),
            maxLines: 4,
          ),
        ],
      ),
    );
  }

   Widget _buildPreferencesSection(BuildContext context, ProfileNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Preferences',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
         const Divider(height: 24),
        const Text('Show Me', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Men'),
              selected: notifier.interestedInGender == 'male',
              onSelected: (selected) {
                if (selected) notifier.interestedInGender = 'male';
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Women'),
              selected: notifier.interestedInGender == 'female',
              onSelected: (selected) {
                if (selected) notifier.interestedInGender = 'female';
              },
            ),
             const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Both'),
              selected: notifier.interestedInGender == 'both',
              onSelected: (selected) {
                if (selected) notifier.interestedInGender = 'both';
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
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
          onChanged: (values) {
            notifier.preferredAgeRange = values;
          },
        ),
        const SizedBox(height: 20),
        Text('Max Distance: ${notifier.preferredDistance.round()} km'),
        Slider(
          value: notifier.preferredDistance,
          min: 1,
          max: 500,
          divisions: 499,
          label: '${notifier.preferredDistance.round()} km',
          onChanged: (value) {
            notifier.preferredDistance = value;
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection(BuildContext context, ProfileNotifier notifier) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, color: Theme.of(context).primaryColor, size: 30),
            const SizedBox(width: 16),
             Expanded(
              child: Text(
                notifier.location != null 
                ? 'Location Updated' 
                : 'Location is not set',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () async {
                await notifier.updateLocation();
                 if (notifier.errorMessage != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(notifier.errorMessage!), backgroundColor: Colors.red),
                  );
                 }
                 else if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Location Updated Successfully!"), backgroundColor: Colors.green),
                  );
                 }
              },
              child: const Text('UPDATE NOW'),
            ),
          ],
        ),
      ),
    );
  }
}
