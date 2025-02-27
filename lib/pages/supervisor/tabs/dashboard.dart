import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/widgets/cifras.dart';
import 'package:plannerop/widgets/quickActions.dart';
import 'package:plannerop/widgets/recentOps.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE0E5EC),
        centerTitle: true, // Centrar el título en el AppBar
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Cifras(),
                const SizedBox(height: 24),
                QuickActions(),
                const SizedBox(height: 24),
                RecentOps()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
