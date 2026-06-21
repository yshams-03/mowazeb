import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../models/commute_result.dart';

class MosqueFinderSection extends StatelessWidget {
  const MosqueFinderSection({super.key, required this.mosques});

  final List<MosqueResult> mosques;

  Future<void> _openMaps(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nearby mosques',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pray at a mosque before you hit the road.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
        const SizedBox(height: 12),
        if (mosques.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No mosques found within 2 km. Try searching on your maps app.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          ...mosques.map(
            (mosque) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(
                  Icons.mosque_outlined,
                  color: AppColors.primaryTeal,
                ),
                title: Text(
                  mosque.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${mosque.formattedDistance} · ${mosque.address}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: OutlinedButton(
                  onPressed: () => _openMaps(mosque.googleMapsUrl),
                  child: const Text('Open in Maps'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
