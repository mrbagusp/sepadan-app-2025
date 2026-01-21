import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import './create_devo_screen.dart'; // Akan dibuat selanjutnya

class DailyDevoManagementScreen extends StatefulWidget {
  const DailyDevoManagementScreen({super.key});

  @override
  _DailyDevoManagementScreenState createState() => _DailyDevoManagementScreenState();
}

class _DailyDevoManagementScreenState extends State<DailyDevoManagementScreen> {
  Future<List<dynamic>> _fetchDevos() async {
    try {
      final response = await http.get(Uri.parse('/api/admin/devos'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load devos');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Devo Management'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchDevos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No devos found.'));
          }

          final devos = snapshot.data!;

          return ListView.builder(
            itemCount: devos.length,
            itemBuilder: (context, index) {
              final devo = devos[index];
              final scheduledDate = DateTime.fromMillisecondsSinceEpoch(devo['scheduled_date']['_seconds'] * 1000);
              final formattedDate = DateFormat.yMMMd().format(scheduledDate);

              return ListTile(
                title: Text(devo['title']),
                subtitle: Text('Scheduled for: $formattedDate'),
                trailing: scheduledDate.isAfter(DateTime.now()) 
                  ? const Icon(Icons.schedule, color: Colors.blue)
                  : const Icon(Icons.check_circle, color: Colors.green),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateDevoScreen()),
          ).then((_) => setState(() {})); // Refresh list after creation
        },
        child: const Icon(Icons.add),
        tooltip: 'Create New Devo',
      ),
    );
  }
}
