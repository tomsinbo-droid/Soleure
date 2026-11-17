import 'package:flutter/material.dart';

class DataTableShell extends StatelessWidget {
  const DataTableShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    );
  }
}
