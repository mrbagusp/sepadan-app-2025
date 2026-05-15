// ============================================================
// 📁 lib/services/version_service.dart
// ✅ Check for app updates from Firestore (Android & iOS)
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionService {
  static final VersionService _instance = VersionService._internal();
  factory VersionService() => _instance;
  VersionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Store URLs
  static const String playStoreUrl = 
      'https://play.google.com/store/apps/details?id=com.sepadan.app';
  static const String appStoreUrl = 
      'https://apps.apple.com/app/sepadan/id123456789'; // Update with real ID

  /// Check if update is available
  /// Call this in main_screen.dart after login
  Future<void> checkForUpdate(BuildContext context) async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      debugPrint('📱 Current version: $currentVersion ($currentBuildNumber)');

      // Get required version from Firestore
      final doc = await _firestore.collection('settings').doc('app_version').get();
      
      if (!doc.exists) {
        debugPrint('⚠️ No version config in Firestore');
        return;
      }

      final data = doc.data()!;
      final latestVersion = data['latest_version'] as String? ?? currentVersion;
      final minBuildNumber = data['min_build_number'] as int? ?? 0;
      final forceUpdate = data['force_update'] as bool? ?? false;
      final updateMessage = data['update_message'] as String? ?? 
          'Versi baru tersedia dengan fitur terbaru! Update sekarang.';

      debugPrint('🌐 Latest: $latestVersion, Min build: $minBuildNumber, Force: $forceUpdate');

      // Check if update needed
      final needsUpdate = currentBuildNumber < minBuildNumber || 
                          _isVersionLower(currentVersion, latestVersion);

      if (needsUpdate && context.mounted) {
        _showUpdateDialog(
          context,
          latestVersion: latestVersion,
          message: updateMessage,
          forceUpdate: forceUpdate,
        );
      }
    } catch (e) {
      debugPrint('❌ Version check error: $e');
    }
  }

  /// Compare versions (e.g., "1.0.0" < "1.0.1")
  bool _isVersionLower(String current, String latest) {
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final l = i < latestParts.length ? latestParts[i] : 0;
      if (c < l) return true;
      if (c > l) return false;
    }
    return false;
  }

  /// Show update dialog
  void _showUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String message,
    required bool forceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) => PopScope(
        canPop: !forceUpdate,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.system_update,
                  color: Colors.deepPurple.shade600,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Update Tersedia! 🎉',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 15),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.new_releases, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Versi $latestVersion',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (forceUpdate) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Update wajib untuk melanjutkan menggunakan aplikasi',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openStore(),
                    icon: const Icon(Icons.download),
                    label: const Text('Update Sekarang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (!forceUpdate) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Nanti Saja',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Open Play Store or App Store based on platform
  Future<void> _openStore() async {
    final String url = Platform.isIOS ? appStoreUrl : playStoreUrl;
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}