// ============================================================
// 📁 lib/services/location_service.dart
// ✅ NEW: Proper location permission handling with dialogs
// ============================================================

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check and request location permission with proper UI feedback
  /// Returns GeoPoint if successful, null if failed
  Future<GeoPoint?> getCurrentLocation(BuildContext context) async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          final shouldOpen = await _showLocationServiceDialog(context);
          if (shouldOpen) {
            await Geolocator.openLocationSettings();
          }
        }
        return null;
      }

      // 2. Check permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // 3. If denied, request permission
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          await _showPermissionExplanationDialog(context);
        }

        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            _showSnackBar(context, 'Location permission denied', Colors.orange);
          }
          return null;
        }
      }

      // 4. If denied forever, guide user to settings
      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          final shouldOpen = await _showPermissionDeniedForeverDialog(context);
          if (shouldOpen) {
            await Geolocator.openAppSettings();
          }
        }
        return null;
      }

      // 5. Get current position
      if (context.mounted) {
        _showSnackBar(context, 'Getting your location...', Colors.blue);
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      if (context.mounted) {
        _showSnackBar(context, 'Location updated!', Colors.green);
      }

      return GeoPoint(position.latitude, position.longitude);

    } catch (e) {
      debugPrint('Location error: $e');
      if (context.mounted) {
        _showSnackBar(context, 'Failed to get location: $e', Colors.red);
      }
      return null;
    }
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(GeoPoint from, GeoPoint to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ) / 1000; // Convert to km
  }

  /// Format distance for display
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '< 1 km away';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km away';
    } else {
      return '${distanceKm.round()} km away';
    }
  }

  // ─────────────────────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────────────────────

  Future<bool> _showLocationServiceDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_off, color: Colors.orange.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Location Disabled'),
          ],
        ),
        content: const Text(
          'Location services are turned off. Please enable location services to find matches near you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showPermissionExplanationDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on, color: Colors.deepPurple.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Location Access'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SEPADAN needs your location to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Find matches near you'),
            _buildBulletPoint('Show distance on profiles'),
            _buildBulletPoint('Improve match recommendations'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Your exact location is never shown to other users',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showPermissionDeniedForeverDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_disabled, color: Colors.red.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Permission Required'),
          ],
        ),
        content: const Text(
          'Location permission was permanently denied. Please enable it in app settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}