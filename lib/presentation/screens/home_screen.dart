import 'package:flutter/material.dart';
import '../widgets/organisms/safety_dashboard.dart';

/// Home Screen - Entry point for the app
/// Simply wraps SafetyDashboard organism for potential future navigation
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafetyDashboard();
  }
}
