
import 'package:flutter/material.dart';
import 'package:sepadan/models/user_preferences.dart';
import 'package:sepadan/services/profile_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _profileService = ProfileService();
  bool _isLoading = true;
  late UserPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    final prefs = await _profileService.getUserPreferences();
    setState(() {
      _preferences = prefs;
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    await _profileService.updateUserPreferences(_preferences);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery Settings'),
        actions: [
          IconButton(
            onPressed: _savePreferences,
            icon: const Icon(Icons.save),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildDistanceSelector(),
                const SizedBox(height: 24),
                _buildAgeRangeSelector(),
                const SizedBox(height: 24),
                _buildInterestedInSelector(),
              ],
            ),
    );
  }

   Widget _buildDistanceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maximum Distance',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _preferences.maxDistanceKm.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                label: '${_preferences.maxDistanceKm} km',
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences.copyWith(maxDistanceKm: value.round());
                  });
                },
              ),
            ),
            Text('${_preferences.maxDistanceKm} km')
          ],
        ),
      ],
    );
  }

  Widget _buildAgeRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age Range',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        RangeSlider(
          values: RangeValues(
            _preferences.ageMin.toDouble(),
            _preferences.ageMax.toDouble(),
          ),
          min: 18,
          max: 70,
          divisions: 52,
          labels: RangeLabels(
            _preferences.ageMin.toString(),
            _preferences.ageMax.toString(),
          ),
          onChanged: (RangeValues values) {
            setState(() {
               _preferences = _preferences.copyWith(
                ageMin: values.start.round(),
                ageMax: values.end.round(),
              );
            });
          },
        ),
         Center(child: Text('${_preferences.ageMin} - ${_preferences.ageMax}'))
      ],
    );
  }

  Widget _buildInterestedInSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interested In',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        DropdownButtonFormField<String>(
          value: _preferences.preferredGender,
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Men')),
            DropdownMenuItem(value: 'female', child: Text('Women')),
            DropdownMenuItem(value: 'everyone', child: Text('Everyone')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                 _preferences = _preferences.copyWith(preferredGender: value);
              });
            }
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
          ),
        ),
      ],
    );
  }
}
