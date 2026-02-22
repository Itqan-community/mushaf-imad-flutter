import 'package:flutter/material.dart';
import 'package:imad_flutter/imad_flutter.dart';

void main() {
  runApp(const MushafSampleApp());
}

class MushafSampleApp extends StatelessWidget {
  const MushafSampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mushaf Imad - Sample',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFD4A574),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFFD4A574),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mushaf Imad'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Reciters',
            subtitle:
                '${ReciterDataProvider.allReciters.length} reciters available',
            icon: Icons.mic,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecitersPage()),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Domain Models',
            subtitle: 'View all Quran data models',
            icon: Icons.data_object,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ModelsPage()),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Theme Preview',
            subtitle: 'Reading theme color schemes',
            icon: Icons.palette,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ThemePage()),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Mushaf Type',
            subtitle: 'Switch between Hafs layouts',
            icon: Icons.menu_book,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MushafTypePage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================
// Reciters Page
// ============================================================
class RecitersPage extends StatelessWidget {
  const RecitersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reciters = ReciterDataProvider.allReciters;
    return Scaffold(
      appBar: AppBar(title: const Text('Available Reciters')),
      body: ListView.builder(
        itemCount: reciters.length,
        itemBuilder: (context, index) {
          final reciter = reciters[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(reciter.nameEnglish),
            subtitle: Text(reciter.nameArabic),
            trailing: Text(
              reciter.rewaya,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Audio URL for Al-Fatiha: ${reciter.getAudioUrl(1)}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// Models Page
// ============================================================
class ModelsPage extends StatelessWidget {
  const ModelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Demonstrate creating model instances
    const verse = Verse(
      verseID: 1,
      humanReadableID: '1_1',
      number: 1,
      text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      textWithoutTashkil: 'بسم الله الرحمن الرحيم',
      uthmanicHafsText: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
      hafsSmartText: 'بسم الله الرحمن الرحيم',
      searchableText: 'بسم الله الرحمن الرحيم',
      chapterNumber: 1,
      pageNumber: 1,
      partNumber: 1,
    );

    const chapter = Chapter(
      identifier: 1,
      number: 1,
      isMeccan: true,
      title: 'الفاتحة',
      arabicTitle: 'الفاتحة',
      englishTitle: 'Al-Fatiha',
      titleCodePoint: '',
      searchableText: 'الفاتحة Al-Fatiha',
      searchableKeywords: 'فاتحة opening',
      versesCount: 7,
    );

    const bookmark = Bookmark(
      id: 'bm_1',
      chapterNumber: 2,
      verseNumber: 255,
      pageNumber: 42,
      createdAt: 1708887600000,
      note: 'Ayat al-Kursi',
      tags: ['favorite', 'daily'],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Domain Models')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ModelCard(
            title: 'Verse',
            properties: {
              'ID': verse.humanReadableID,
              'Number': '${verse.number}',
              'Chapter': '${verse.chapterNumber}',
              'Page': '${verse.pageNumber}',
              'Text': verse.text,
            },
          ),
          const SizedBox(height: 12),
          _ModelCard(
            title: 'Chapter',
            properties: {
              'Number': '${chapter.number}',
              'Arabic': chapter.arabicTitle,
              'English': chapter.englishTitle,
              'Meccan': '${chapter.isMeccan}',
              'Verses': '${chapter.versesCount}',
              'Display (en)': chapter.getDisplayTitle(),
              'Display (ar)': chapter.getDisplayTitle(languageCode: 'ar'),
            },
          ),
          const SizedBox(height: 12),
          _ModelCard(
            title: 'Bookmark',
            properties: {
              'ID': bookmark.id,
              'Reference': bookmark.verseReference,
              'Page': '${bookmark.pageNumber}',
              'Note': bookmark.note,
              'Tags': bookmark.tags.join(', '),
              'Has Note': '${bookmark.hasNote}',
              'Has Tags': '${bookmark.hasTags}',
            },
          ),
          const SizedBox(height: 12),
          _ModelCard(
            title: 'Part (Juz)',
            properties: {
              'Number': '1',
              'Arabic': 'الجزء الأول',
              'English': 'Juz 1',
            },
          ),
          const SizedBox(height: 12),
          _ModelCard(
            title: 'AudioPlayerState',
            properties: {
              'State': PlaybackState.idle.name,
              'Position': '0 ms',
              'Duration': '0 ms',
              'Progress': '0.0%',
              'Playing': 'false',
            },
          ),
          const SizedBox(height: 12),
          _ModelCard(
            title: 'MushafType',
            properties: {
              'Types': MushafType.values.map((t) => t.name).join(', '),
            },
          ),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final String title;
  final Map<String, String> properties;

  const _ModelCard({required this.title, required this.properties});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...properties.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${e.key}:',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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

// ============================================================
// Theme Page
// ============================================================
class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Themes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: ReadingTheme.values.map((theme) {
          final data = ReadingThemeData.fromTheme(theme);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: data.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: data.accentColor, width: 1),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.name.toUpperCase(),
                    style: TextStyle(
                      color: data.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                    style: TextStyle(
                      color: data.textColor,
                      fontSize: 24,
                      fontFamily: 'serif',
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'In the name of Allah, the Most Gracious, the Most Merciful',
                    style: TextStyle(
                      color: data.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ColorChip('Background', data.backgroundColor),
                      const SizedBox(width: 8),
                      _ColorChip('Surface', data.surfaceColor),
                      const SizedBox(width: 8),
                      _ColorChip('Accent', data.accentColor),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

// ============================================================
// MushafType Page
// ============================================================
class MushafTypePage extends StatefulWidget {
  const MushafTypePage({super.key});

  @override
  State<MushafTypePage> createState() => _MushafTypePageState();
}

class _MushafTypePageState extends State<MushafTypePage> {
  MushafType _selected = MushafType.hafs1441;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mushaf Type')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Mushaf Layout',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...MushafType.values.map(
              (type) => RadioListTile<MushafType>(
                title: Text(
                  type == MushafType.hafs1441
                      ? 'Hafs 1441 (Modern)'
                      : 'Hafs 1405 (Traditional)',
                ),
                subtitle: Text(
                  type == MushafType.hafs1441
                      ? 'Modern layout from 1441 Hijri'
                      : 'Traditional layout from 1405 Hijri',
                ),
                value: type,
                groupValue: _selected,
                onChanged: (value) {
                  if (value != null) setState(() => _selected = value);
                },
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected: ${_selected.name}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This mushaf type determines how verses are mapped '
                      'to pages and which verse markers/highlights are used.',
                      style: Theme.of(context).textTheme.bodyMedium,
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
