import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/quran/quran_data_provider.dart';

/// VerseFasel — renders a verse number marker (circle with Arabic numeral).
///
/// Port of the Android VerseFasel composable.
class VerseFasel extends StatelessWidget {
  final int number;
  final double size;

  const VerseFasel({super.key, required this.number, this.size = 28});

  @override
  Widget build(BuildContext context) {
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
            padding: EdgeInsets.only(
              top: size * 0.05,
            ), // Translate the y offset from Android
            child: Text(
              QuranDataProvider.toArabicNumerals(number),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Android uses pure Color.Black
                fontFamily:
                    'QuranNumbers', // Using the custom QuranNumbers font requested
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
