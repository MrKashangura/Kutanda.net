// lib/widgets/csr_analytics_widget.dart
import 'package:flutter/material.dart';

import '../screens/csr_analytics_screen.dart';

/// A wrapper widget that displays the CSR analytics dashboard.
/// This can be used to embed the analytics functionality in other screens.
class CSRAnalyticsWidget extends StatelessWidget {
  final int? lastDays;
  final bool showHeader;
  
  const CSRAnalyticsWidget({
    super.key,
    this.lastDays = 7,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showHeader ? AppBar(
        title: const Text("Analytics Dashboard"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ) : null,
      body: const CSRAnalyticsScreen(),
    );
  }
}