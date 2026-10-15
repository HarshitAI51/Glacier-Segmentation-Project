import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/studio_screen.dart';
import 'theme/glacier_theme.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GlacierApp());
}

class GlacierApp extends StatelessWidget {
  const GlacierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlacierAI Studio',
      debugShowCheckedModeBanner: false,
      theme: GlacierTheme.lightTheme,
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _selectedIndex = 0;
  bool _backendOnline = false;

  @override
  void initState() {
    super.initState();
    _checkBackendStatus();
  }

  Future<void> _checkBackendStatus() async {
    try {
      final res = await ApiService.checkHealth();
      if (mounted) {
        setState(() => _backendOnline = res['status'] == 'ok');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _backendOnline = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onNavigateToStudio: () => setState(() => _selectedIndex = 1),
      ),
      const StudioScreen(),
    ];

    return Scaffold(
      backgroundColor: GlacierColors.canvas,
      body: SafeArea(
        child: Row(
          children: [
            // Left Floating Dark Pill Sidebar (Inspired by Reference 1 & 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              child: Container(
                width: 72,
                decoration: BoxDecoration(
                  color: GlacierColors.darkForest,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Logo Icon Capsule
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: GlacierColors.darkHover,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.ac_unit_rounded,
                          color: Color(0xFF86EFAC), // Soft mint green
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Nav item 0: Dashboard
                    _navIcon(
                      icon: Icons.grid_view_rounded,
                      index: 0,
                      tooltip: 'Dashboard Overview',
                    ),
                    const SizedBox(height: 14),

                    // Nav item 1: Studio
                    _navIcon(
                      icon: Icons.landscape_rounded,
                      index: 1,
                      tooltip: 'Neural Segmentation Studio',
                    ),
                    const Spacer(),

                    // Backend Status Indicator Dot
                    Tooltip(
                      message: _backendOnline
                          ? 'FastAPI Engine Online (127.0.0.1:8000)'
                          : 'Backend Offline',
                      child: GestureDetector(
                        onTap: _checkBackendStatus,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: GlacierColors.darkHover,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _backendOnline
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFFF87171),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_backendOnline
                                            ? const Color(0xFF4ADE80)
                                            : const Color(0xFFF87171))
                                        .withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Profile / Monogram Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'GA',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: GlacierColors.darkForest,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Main Content Canvas
            Expanded(
              child: pages[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navIcon({
    required IconData icon,
    required int index,
    required String tooltip,
  }) {
    final isSelected = _selectedIndex == index;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _selectedIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isSelected
                  ? GlacierColors.darkForest
                  : Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }
}
