import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 76, this.fit = BoxFit.contain});

  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
        color: const Color(0xFF0C1A29),
        child: Image.asset(
          AppAssets.logo,
          fit: fit,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF173A5E),
            alignment: Alignment.center,
            child: const Text(
              'SOLÉURE · DIECAST 1:64',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
