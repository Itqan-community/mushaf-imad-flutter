import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/quran/quran_data_provider.dart';

/// VerseFasel — renders a verse number marker (circle with Arabic numeral).
///
/// Port of the Android VerseFasel composable.
///
/// [useArabicNumerals] controls the numeral style:
/// - `false` (default): uses Western digits (0-9) rendered via the
///   `QuranNumbers.ttf` font which maps them to Arabic glyphs.
/// - `true`: uses Arabic-Indic Unicode digits (٠١٢٣...) with the system font,
///   no special font required.
class VerseFasel extends StatelessWidget {
  final int number;
  final double size;

  /// When true, displays Arabic-Indic Unicode numerals (٠١٢٣...) using the
  /// system font with RTL direction. When false (default), uses Western digits
  /// with the QuranNumbers.ttf font which maps them to Arabic glyphs.
  final bool useArabicNumerals;

  const VerseFasel({
    super.key,
    required this.number,
    this.size = 28,
    this.useArabicNumerals = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = useArabicNumerals
        ? QuranDataProvider.toArabicNumerals(number)
        : number.toString();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The fasel SVG graphic (un-tinted, exactly as Android does it)
          SvgPicture.asset(
            'assets/fasel.svg',
            package: 'imad_flutter',
            width: size,
            height: size,
          ),
          // The verse number displayed inside the fasel graphic
          Padding(
            padding: EdgeInsets.only(top: size * 0.05),
            child: Text(
              displayText,
              textAlign: TextAlign.center,
              textDirection:
                  useArabicNumerals ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: useArabicNumerals ? null : 'QuranNumbers',
                package: useArabicNumerals ? null : 'imad_flutter',
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
