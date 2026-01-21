
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/firebase_options.dart';

// To run this script from the project root, use the following command:
// cd myapp && dart run scripts/populate_db.dart

void main() async {
  // This is needed to use Flutter packages in a command-line app
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Firebase Initialized.');

  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('daily_devotionals');

  print('Adding sample devotionals...');

  final devos = [
    {
      'title': 'Morning Gratitude',
      'content': 'Start your day by listing three things you are grateful for. Gratitude shifts your focus to the positive and sets a joyful tone for the day.',
      'date': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
    },
    {
      'title': 'The Power of Forgiveness',
      'content': 'Holding onto resentment is like drinking poison and expecting the other person to die. Practice forgiveness today, for your own peace.',
      'date': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
    },
    {
      'title': 'Embracing the Present',
      'content': 'Worrying about the future or dwelling on the past robs you of the only time you truly have: the present moment. Be here now.',
      'date': Timestamp.now(),
    },
  ];

  for (var devo in devos) {
    try {
      final docRef = await collection.add(devo);
      print("Added devotional with ID: \${docRef.id}");
    } catch (e) {
      print("Error adding a devotional: \$e");
    }
  }

  print('\\nFinished populating database.');
}
