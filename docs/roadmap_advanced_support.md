# Future Roadmap: Advanced Narrations & Editions

The Mushaf Imad project aims to be a comprehensive platform for Quranic studies. This roadmap outlines the strategic direction for supporting diverse recitations and historical editions.

## 1. Warsh 'an Nafi' Support (ورش عن نافع)

Warsh is the primary narration used in North and West Africa. Implementing it requires significant data and architectural adjustments.

### Technical Requirements:
- **Alternative Verse Demarcation**: Supporting the "Medina I" verse counting system (6,214 verses) vs the current Hafs (6,236 verses).
- **Rasm (Orthography) Updates**: Using specific Warsh fonts and assets that reflect its unique spelling (e.g., *Maliki* vs *Māliki*).
- **Audio Synchronization**: Acquiring new Ayah-Timing data for Warsh reciters (e.g., Al-Hosary with Warsh narration).
- **Metadata Separation**: Modifying `QuranRepository` to switch between `riwayah` types, affecting bookmarks and reading history markers.

## 2. 1405 Medina Edition Support (مصحف المدينة القديم)

The 1405 AH edition is the "Gold Standard" for many who memorized the Quran in the late 20th century.

### Characteristics:
- **Visual Style**: Distinct, slightly thicker calligraphy by Sheikh Uthman Taha.
- **Layout Consistency**: Maintains the exact 15-line layout but with legacy ornamentation.

### Implementation Plan:
- **Asset Acquisition**: High-resolution scans of the 1405 edition.
- **Verse Mapping**: Since the page breaks are identical to the modern edition, we can reuse existing logical mapping but need new bounding box data for highlighting.
- **Switchable Content**: Allowing users to choose between "Modern Medina" and "Classic 1405" in the settings.

## 3. Extension Strategy

To support these, the library will adopt a **Provider-Based Architecture**:
- `MushafDataProvider`: An interface that provides images, verses, and bounding boxes.
- `HafsMadaniProvider` (Current implementation).
- `WarshMadaniProvider` (Planned).
- `Hafs1405Provider` (Planned).

## 4. Estimated Timeline
- **Q2 2026**: Initial support for 1405 Edition images.
- **Q3 2026**: Beta support for Warsh narration verse data and count.
- **Q4 2026**: full multi-riwayah synchronization.
