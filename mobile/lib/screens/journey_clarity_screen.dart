import 'package:flutter/material.dart';
import '../models/pnr_result.dart';

class JourneyClarityScreen extends StatelessWidget {
  const JourneyClarityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pnrResult = ModalRoute.of(context)!.settings.arguments as PnrResult;

    final status = pnrResult.status;
    final journey = pnrResult.journey;
    final chart = pnrResult.chart;
    final clarity = pnrResult.clarity;

    String statusText;
    String statusSubtext;
    bool showFindBuddy;

    switch (status.type) {
      case 'WL':
        statusText = 'Waiting List ${status.currentPosition}';
        statusSubtext = 'Started at WL ${status.originalPosition}';
        showFindBuddy = true;
        break;
      case 'RAC':
        statusText = 'RAC ${status.currentPosition}';
        statusSubtext = '';
        showFindBuddy = true;
        break;
      case 'CNF':
        statusText = 'Confirmed';
        statusSubtext = '';
        showFindBuddy = false;
        break;
      default:
        statusText = 'Unknown';
        statusSubtext = '';
        showFindBuddy = false;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Journey Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Journey summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${journey.trainNumber} ${journey.trainName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${journey.from} → ${journey.to}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${journey.boardingDate} • ${journey.trainClass}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status block
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (statusSubtext.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(statusSubtext),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Chart timing
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chart.prepared ? 'Chart prepared' : 'Chart not prepared yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (!chart.prepared) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Expected around ${_formatTime(chart.expectedTime)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Clarity explanation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clarity.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(clarity.body),
                    const SizedBox(height: 12),
                    ...clarity.tips.map((tip) => Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('• $tip'),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Primary CTA
            if (showFindBuddy)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/find-buddy-intro',
                    arguments: pnrResult,
                  );
                },
                child: const Text('Find a Buddy'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Helper flow for confirmed passengers – coming soon')),
                  );
                },
                child: const Text('Help a Waitlisted Passenger'),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
