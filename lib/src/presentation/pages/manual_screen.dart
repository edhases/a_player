import 'package:flutter/material.dart';
import '../../core/utils/localization.dart';

class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    // Using a list of sections for cleaner code
    final sections = [
      _ManualSection(loc.manualIntroTitle, loc.manualIntroDesc,
          isExpanded: true),
      _ManualSection(loc.manualBasicsTitle, loc.manualBasicsDesc),
      _ManualSection(loc.manualLibraryTitle, loc.manualLibraryDesc),
      _ManualSection(loc.manualYoutubeTitle, loc.manualYoutubeDesc),
      _ManualSection(loc.manualPlaylistsTitle, loc.manualPlaylistsDesc),
      _ManualSection(loc.manualSettingsTitle, loc.manualSettingsDesc),
      _ManualSection(
          loc.manualTroubleshootingTitle, loc.manualTroubleshootingDesc),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.manualTitle),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              initiallyExpanded: section.isExpanded,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: Text(
                section.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 18,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _buildStyledText(context, section.content),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStyledText(BuildContext context, String text) {
    List<InlineSpan> spans = [];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        // Bold text (between **)
        spans.add(TextSpan(
          text: parts[i],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else {
        // Normal text
        spans.add(TextSpan(text: parts[i]));
      }
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: TextStyle(
          height: 1.6,
          fontSize: 16,
          color: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.color
              ?.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _ManualSection {
  final String title;
  final String content;
  final bool isExpanded;

  _ManualSection(this.title, this.content, {this.isExpanded = false});
}
