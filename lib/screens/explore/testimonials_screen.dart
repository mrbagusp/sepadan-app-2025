import 'package:flutter/material.dart';

class TestimonialsScreen extends StatelessWidget {
  const TestimonialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data
    final List<Map<String, String>> dummyTestimonials = [
      {
        'name': 'Rina',
        'story': 'Puji Tuhan, melalui aplikasi SEPADAN saya bertemu dengan pasangan hidup yang sevisi dalam iman.',
        'image': 'https://i.pravatar.cc/150?u=rina',
      },
      {
        'name': 'Kevin',
        'story': 'Komunitas di sini sangat menguatkan. Fitur Daily Devo sangat membantu pertumbuhan rohani saya setiap pagi.',
        'image': 'https://i.pravatar.cc/150?u=kevin',
      },
      {
        'name': 'Maria',
        'story': 'Awalnya ragu, tapi setelah mencoba, saya merasa aman karena lingkungannya sesama orang percaya.',
        'image': 'https://i.pravatar.cc/150?u=maria',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Testimonials'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dummyTestimonials.length,
        itemBuilder: (context, index) {
          final test = dummyTestimonials[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(test['image']!),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    test['story']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '- ${test['name']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
