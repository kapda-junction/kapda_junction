import 'package:flutter/material.dart';

/// Shell for ShellRoute — just passes child through.
/// Navigation is provided by [AdminDrawer] which each page mounts as its drawer.
class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
