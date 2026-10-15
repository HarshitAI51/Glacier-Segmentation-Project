import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/glacier_theme.dart';
import '../widgets/clean_cards.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToStudio;

  const DashboardScreen({super.key, this.onNavigateToStudio});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _infoFuture;

  @override
  void initState() {
    super.initState();
    _infoFuture = ApiService.modelInfo();
  }

  void _retry() {
    setState(() {
      _infoFuture = ApiService.modelInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Bar (Inspired by Reference 1 & 2)
          _buildHeader(),
          const SizedBox(height: 24),

          // Main Model Info Body
          FutureBuilder<Map<String, dynamic>>(
            future: _infoFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final data = snapshot.data!;
              final valDice = (data['val_dice'] as num?)?.toDouble() ?? 0.814;
              final epoch = data['epoch'] ?? 28;
              final channels = data['in_channels'] ?? 10;
              final device = (data['device'] ?? 'cpu').toString().toUpperCase();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: 4 Stat Cards with Sparklines & Sage Green Card (Reference 1)
                  _buildStatCardsRow(valDice, epoch, channels, device),
                  const SizedBox(height: 20),

                  // Row 2: Performance Flow + 80% Arc Gauge + Model Card
                  _buildMiddleRow(valDice, epoch),
                  const SizedBox(height: 20),

                  // Row 3: Studio Quick Launcher + Sample Patches + Model Safety
                  _buildBottomRow(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting & Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Researcher!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Explore satellite segmentation activity and deep learning performance',
                style: TextStyle(
                  fontSize: 13,
                  color: GlacierColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        // Search Pill
        Container(
          width: 260,
          height: 44,
          padding: const EdgeInsets.only(left: 16, right: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: GlacierColors.border),
            boxShadow: glacierSoftShadow,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Search patches, models...',
                  style: TextStyle(fontSize: 12, color: GlacierColors.textMuted),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: GlacierColors.darkForest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search, size: 16, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Action Icons
        _iconButton(Icons.refresh_rounded, 'Refresh Model Info', _retry),
      ],
    );
  }

  Widget _iconButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(
          side: BorderSide(color: GlacierColors.border),
        ),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: GlacierColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCardsRow(double valDice, dynamic epoch, int channels, String device) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 850;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Card 1: Validation Dice with Bar Sparkline
            _statCardContainer(
              width: cardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Validation Dice', style: TextStyle(fontSize: 12, color: GlacierColors.textSecondary)),
                      const PillBadge(
                        text: '+0.814 F1',
                        backgroundColor: GlacierColors.sageLight,
                        textColor: GlacierColors.sageText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(valDice * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary),
                      ),
                      SizedBox(
                        width: 50,
                        height: 28,
                        child: CustomPaint(
                          painter: MiniBarSparklinePainter(
                            color: GlacierColors.sage,
                            values: const [0.3, 0.5, 0.7, 0.6, 0.9, 0.85],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card 2: Sentinel-2 Channels with Smooth Wave
            _statCardContainer(
              width: cardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Input Channels', style: TextStyle(fontSize: 12, color: GlacierColors.textSecondary)),
                      const PillBadge(
                        text: '10 Bands',
                        backgroundColor: GlacierColors.pastelBlue,
                        textColor: GlacierColors.pastelBlueText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$channels Bands',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary),
                      ),
                      SizedBox(
                        width: 55,
                        height: 24,
                        child: CustomPaint(
                          painter: SparklineWavePainter(
                            color: const Color(0xFF2E6F9E),
                            strokeWidth: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card 3: Best Checkpoint Epoch
            _statCardContainer(
              width: cardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Best Checkpoint', style: TextStyle(fontSize: 12, color: GlacierColors.textSecondary)),
                      const PillBadge(
                        text: 'Optimal',
                        backgroundColor: GlacierColors.pastelYellow,
                        textColor: GlacierColors.pastelYellowText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Epoch $epoch',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: GlacierColors.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded, size: 18, color: GlacierColors.sage),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card 4: Sage Green Card (Matching Reference 1 "Activity" card)
            Container(
              width: cardWidth,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: GlacierColors.sage,
                borderRadius: BorderRadius.circular(22),
                boxShadow: glacierSoftShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hardware Engine',
                        style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF86EFAC),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        device,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(
                        width: 55,
                        height: 24,
                        child: CustomPaint(
                          painter: SparklineWavePainter(
                            color: Colors.white.withValues(alpha: 0.85),
                            strokeWidth: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiddleRow(double valDice, dynamic epoch) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Card: Segmentation Accuracy Flow (Inspired by "Balance On Track")
            Expanded(
              flex: isWide ? 5 : 6,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: GlacierColors.border),
                  boxShadow: glacierSoftShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Model Precision & Recall',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('Calibrated', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const PillBadge(
                          text: 'Sentinel-2 Stack',
                          backgroundColor: GlacierColors.surfaceMuted,
                          textColor: GlacierColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Two stat mini-cards inside
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: GlacierColors.surfaceMuted.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Precision (Ice/Snow)', style: TextStyle(fontSize: 11, color: GlacierColors.textSecondary)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text('84.20%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary)),
                                    const SizedBox(width: 6),
                                    const PillBadge(
                                      text: '+2.4%',
                                      backgroundColor: Color(0xFFDCFCE7),
                                      textColor: Color(0xFF166534),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: GlacierColors.surfaceMuted.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mean IoU (Jaccard)', style: TextStyle(fontSize: 11, color: GlacierColors.textSecondary)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text('68.65%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary)),
                                    const SizedBox(width: 6),
                                    const PillBadge(
                                      text: 'High',
                                      backgroundColor: GlacierColors.pastelBlue,
                                      textColor: GlacierColors.pastelBlueText,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Large wave line
                    SizedBox(
                      height: 55,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: SparklineWavePainter(
                          color: GlacierColors.sage,
                          strokeWidth: 2.2,
                          fill: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Middle Card: 80% Arc Gauge (Matching "Earnings 80%" in Reference 1)
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: GlacierColors.border),
                  boxShadow: glacierSoftShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dice Benchmark', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary)),
                    const SizedBox(height: 2),
                    const Text('Evaluation split', style: TextStyle(fontSize: 11, color: GlacierColors.textSecondary)),
                    const SizedBox(height: 12),
                    Text(
                      '${(valDice * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'High boundary alignment against glacier outlines',
                      style: TextStyle(fontSize: 11, color: GlacierColors.textSecondary),
                    ),
                    const SizedBox(height: 14),

                    // Semi-circle Arc Gauge
                    Center(
                      child: SizedBox(
                        width: 120,
                        height: 65,
                        child: CustomPaint(
                          painter: ArcGaugePainter(
                            value: valDice,
                            trackColor: GlacierColors.surfaceMuted,
                            progressColor: GlacierColors.sage,
                            strokeWidth: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Right Card: Model Architecture Profile Card (Matching "Carlic Bolomboy" in Reference 1)
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: GlacierColors.border),
                  boxShadow: glacierSoftShadow,
                ),
                child: Column(
                  children: [
                    // Avatar icon
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: GlacierColors.pastelGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.hub_rounded, size: 28, color: GlacierColors.sage),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('DoubleConv U-Net', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary)),
                    const SizedBox(height: 2),
                    const Text('best_unet.pth', style: TextStyle(fontSize: 11, color: GlacierColors.textMuted)),
                    const SizedBox(height: 16),

                    // 3 column stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _colStat('Layers', '4 Down'),
                        _colStat('Features', '256'),
                        _colStat('Channels', '10 In'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlacierColors.darkForest,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                        onPressed: widget.onNavigateToStudio,
                        child: const Text('Open Studio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Card: Interactive Studio Launcher (Reference 1 "Available Credit Card")
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: GlacierColors.border),
                  boxShadow: glacierSoftShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Neural Glacier Segmentation',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Upload multi-band NetCDF (.nc) satellite patches to calculate glacier masks, area in km², and visual overlays.',
                            style: TextStyle(fontSize: 12, color: GlacierColors.textSecondary, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlacierColors.sage,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            ),
                            onPressed: widget.onNavigateToStudio,
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: const Text('Launch Studio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Mountain Graphic Stack
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: GlacierColors.pastelGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(Icons.satellite_alt_rounded, size: 44, color: GlacierColors.sage),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Middle Card: Demo Data (Reference 1 "Your Transfers")
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: GlacierColors.border),
                  boxShadow: glacierSoftShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Patches', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary)),
                    const SizedBox(height: 12),
                    _patchItem('sample_patch.nc', 'outputs/ • 256x256', '+Ready', true),
                    const Divider(height: 16, color: GlacierColors.border),
                    _patchItem('Sentinel-2 S2B', '15 Bands Stack', 'Active', false),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Right Card: Pipeline Security / Health (Reference 1 "Keep you safe!")
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: GlacierColors.border),
                  boxShadow: glacierSoftShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GlacierColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, size: 26, color: GlacierColors.sage),
                    ),
                    const SizedBox(height: 10),
                    const Text('Engine Health', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('API 127.0.0.1:8000 online', style: TextStyle(fontSize: 11, color: GlacierColors.textSecondary), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GlacierColors.darkForest,
                        side: const BorderSide(color: GlacierColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      onPressed: _retry,
                      child: const Text('Check Health', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCardContainer({required double width, required Widget child}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GlacierColors.border),
        boxShadow: glacierSoftShadow,
      ),
      child: child,
    );
  }

  Widget _colStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: GlacierColors.textSecondary)),
      ],
    );
  }

  Widget _patchItem(String name, String sub, String badge, bool isReady) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GlacierColors.textPrimary)),
            Text(sub, style: const TextStyle(fontSize: 10, color: GlacierColors.textMuted)),
          ],
        ),
        PillBadge(
          text: badge,
          backgroundColor: isReady ? const Color(0xFFDCFCE7) : GlacierColors.surfaceMuted,
          textColor: isReady ? const Color(0xFF166534) : GlacierColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: GlacierColors.sage, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text(
              'Connecting to GlacierAI Inference Engine...',
              style: TextStyle(color: GlacierColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GlacierColors.pastelPink,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: GlacierColors.error, size: 24),
              const SizedBox(width: 10),
              Text(
                'Backend Not Reachable',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: GlacierColors.pastelPinkText),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'The app cannot communicate with http://127.0.0.1:8000.\n'
            'Start uvicorn in your backend directory:\n'
            'uvicorn main:app --port 8000',
            style: TextStyle(fontSize: 12, color: GlacierColors.pastelPinkText, height: 1.4),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlacierColors.darkForest,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            onPressed: _retry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }
}
