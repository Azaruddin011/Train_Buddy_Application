import 'package:flutter/material.dart';
import '../models/pnr_result.dart';

class FindBuddyIntroScreen extends StatelessWidget {
  const FindBuddyIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final pnrResult = args is PnrResult ? args : null;

    if (pnrResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Find a Confirmed Co‑Passenger')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'Please verify your PNR first to find buddies for your journey.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/pnr');
                },
                child: const Text('Verify PNR'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Find a Confirmed Co‑Passenger')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Text(
              'Connect with verified confirmed passengers on your train and class.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // What you get
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What you get',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    _Bullet(text: 'Verified co‑passenger discovery'),
                    _Bullet(text: 'Consent‑based connection (no spam)'),
                    _Bullet(text: 'Basic comfort filters (gender, language, age group)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // What we DO NOT do
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What we DO NOT do',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    _Bullet(text: 'No ticket resale or transfer'),
                    _Bullet(text: 'No guaranteed confirmation'),
                    _Bullet(text: 'No payment between passengers'),
                    _Bullet(text: 'No TTE coordination'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Price CTA
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Premium WL Coordination – ₹399 (one journey)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/paywall',
                          arguments: pnrResult,
                        );
                      },
                      child: const Text('Continue for ₹399'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Maybe later'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
