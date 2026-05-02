import 'package:flutter/material.dart';
import 'user_management_screen.dart';
import 'moderation_screen.dart';
import 'daily_devo_management_screen.dart';
import 'payment_gateway_settings_screen.dart';
import 'tips_pdkt_management_screen.dart';
import 'dummy_data_generator.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin Panel',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: 'Generate Dummy Users',
              onPressed: () => _showGenerateDialog(context),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.people, color: Colors.white), text: 'Users'),
              Tab(icon: Icon(Icons.gavel, color: Colors.white), text: 'Moderation'),
              Tab(icon: Icon(Icons.book, color: Colors.white), text: 'Daily Devo'),
              Tab(icon: Icon(Icons.lightbulb, color: Colors.white), text: 'Tips PDKT'),
              Tab(icon: Icon(Icons.payment, color: Colors.white), text: 'Payments'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UserManagementScreen(),
            ModerationScreen(),
            DailyDevoManagementScreen(),
            TipsPdktManagementScreen(),
            PaymentGatewaySettingsScreen(),
          ],
        ),
      ),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people, color: Colors.deepPurple),
            const SizedBox(width: 12),
            const Text('Dummy Users'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih aksi untuk dummy users:'),
            const SizedBox(height: 16),
            Text(
              '• Generate: Buat 100 user dummy (50 pria, 50 wanita)\n'
                  '• Delete: Hapus semua dummy users',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteAllDummies(context);
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _generateDummies(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Generate 100'),
          ),
        ],
      ),
    );
  }

  void _generateDummies(BuildContext context) {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _GenerateProgressDialog(),
    );
  }

  void _deleteAllDummies(BuildContext context) {
    // Show progress dialog for deletion
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DeleteProgressDialog(),
    );
  }
}

// ============================================================
// Progress Dialog untuk Generate
// ============================================================
class _GenerateProgressDialog extends StatefulWidget {
  @override
  State<_GenerateProgressDialog> createState() => _GenerateProgressDialogState();
}

class _GenerateProgressDialogState extends State<_GenerateProgressDialog> {
  int _progress = 0;
  int _total = 100;
  bool _isDone = false;
  String _status = 'Starting...';

  @override
  void initState() {
    super.initState();
    _startGenerate();
  }

  Future<void> _startGenerate() async {
    await DummyDataGenerator.generateAll(
      context: context,
      onProgress: (current, total) {
        if (mounted) {
          setState(() {
            _progress = current;
            _total = total;
            _status = 'Creating user $current of $total...';
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDone = true;
        _status = 'Done! Created 100 dummy users.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (!_isDone)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Text(_isDone ? 'Complete!' : 'Generating...'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _total > 0 ? _progress / _total : 0,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
          const SizedBox(height: 16),
          Text(_status),
          const SizedBox(height: 8),
          Text(
            '$_progress / $_total users',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        if (_isDone)
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
      ],
    );
  }
}

// ============================================================
// Progress Dialog untuk Delete
// ============================================================
class _DeleteProgressDialog extends StatefulWidget {
  @override
  State<_DeleteProgressDialog> createState() => _DeleteProgressDialogState();
}

class _DeleteProgressDialogState extends State<_DeleteProgressDialog> {
  int _progress = 0;
  int _total = 0;
  bool _isDone = false;
  String _status = 'Finding dummy users...';

  @override
  void initState() {
    super.initState();
    _startDelete();
  }

  Future<void> _startDelete() async {
    await DummyDataGenerator.deleteAllDummies(
      onProgress: (current, total) {
        if (mounted) {
          setState(() {
            _progress = current;
            _total = total;
            _status = 'Deleting user $current of $total...';
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDone = true;
        _status = _total > 0
            ? 'Done! Deleted $_total dummy users.'
            : 'No dummy users found.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (!_isDone)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
            )
          else
            Icon(
              _total > 0 ? Icons.check_circle : Icons.info,
              color: _total > 0 ? Colors.green : Colors.orange,
            ),
          const SizedBox(width: 12),
          Text(_isDone ? 'Complete!' : 'Deleting...'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_total > 0)
            LinearProgressIndicator(
              value: _total > 0 ? _progress / _total : 0,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          const SizedBox(height: 16),
          Text(_status),
          if (_total > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$_progress / $_total users',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
      actions: [
        if (_isDone)
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
      ],
    );
  }
}