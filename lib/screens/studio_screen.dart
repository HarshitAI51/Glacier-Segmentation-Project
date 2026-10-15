import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/glacier_theme.dart';
import '../widgets/clean_cards.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  String? selectedPath;
  PlatformFile? selectedFile;
  bool loading = false;
  String? errorMessage;
  Map<String, dynamic>? result;
  final TextEditingController _pixelSizeController = TextEditingController(text: '10.0');

  @override
  void dispose() {
    _pixelSizeController.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    try {
      final res = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['nc'],
        withData: true,
      );
      if (res != null && res.files.isNotEmpty) {
        setState(() {
          selectedFile = res.files.first;
          selectedPath = selectedFile?.path;
          result = null;
          errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => errorMessage = 'Failed to pick file: $e');
    }
  }

  Future<void> runPrediction({String? customPath}) async {
    final path = customPath ?? selectedPath;
    final file = selectedFile;

    if (path == null && (file == null || file.bytes == null)) {
      setState(() => errorMessage = 'Please select a NetCDF (.nc) file first.');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final pixelSize = double.tryParse(_pixelSizeController.text.trim());
      Map<String, dynamic> res;

      // Always prefer bytes (web-compatible and universal)
      if (file != null && file.bytes != null) {
        res = await ApiService.predict(
          path ?? file.name,
          pixelSize: pixelSize,
          bytes: file.bytes,
          filename: file.name.isNotEmpty ? file.name : 'patch.nc',
        );
      } else if (path != null && path.isNotEmpty) {
        res = await ApiService.predict(path, pixelSize: pixelSize);
      } else {
        throw Exception('No valid file data found.');
      }

      setState(() => result = res);
    } catch (e) {
      setState(() => errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> savePng(String key, String defaultName) async {
    if (result == null || result![key] == null) return;
    try {
      final bytes = base64Decode(result![key]);
      final out = await FilePicker.saveFile(
        dialogTitle: 'Save Output Image',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['png'],
        bytes: bytes,
      );
      if (out != null) {
        if (!kIsWeb) {
          await File(out).writeAsBytes(bytes);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully exported to ${kIsWeb ? defaultName : out}'),
              backgroundColor: GlacierColors.sage,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: GlacierColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showZoomDialog(String title, String b64) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: glacierSoftShadow,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: GlacierColors.textPrimary)),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(backgroundColor: GlacierColors.surfaceMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 6.0,
                    child: Image.memory(base64Decode(b64), fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          _buildHeader(),
          const SizedBox(height: 20),

          // Control Card (File Selection, Resolution, Inference Action)
          _buildControlsCard(),
          const SizedBox(height: 16),

          // Error Banner if any
          if (errorMessage != null) ...[
            _buildErrorBanner(errorMessage!),
            const SizedBox(height: 16),
          ],

          // Loading State
          if (loading) ...[
            _buildLoadingIndicator(),
            const SizedBox(height: 20),
          ],

          // Results Presentation
          if (result != null) ...[
            // Soft Pastel Metric Pills (Inspired by Reference 2)
            _buildResultsMetricsBanner(),
            const SizedBox(height: 20),

            // Tri-View Gallery (RGB, Mask, Overlay)
            _buildTriViewGallery(),
            const SizedBox(height: 20),

            // Ground-Truth Validation Metrics (if present)
            if (result!['metrics'] != null) ...[
              _buildMetricsCard(result!['metrics']),
              const SizedBox(height: 20),
            ],
          ] else if (!loading) ...[
            _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Glacier Segmentation Studio', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text(
              'Upload NetCDF satellite patches (.nc) for neural segmentation, area estimation, and validation',
              style: TextStyle(fontSize: 13, color: GlacierColors.textSecondary),
            ),
          ],
        ),
        const PillBadge(
          text: 'Sentinel-2 S2B Ready',
          backgroundColor: GlacierColors.pastelGreen,
          textColor: GlacierColors.pastelGreenText,
          icon: Icons.satellite_alt_rounded,
        ),
      ],
    );
  }

  Widget _buildControlsCard() {
    final fileName = selectedFile?.name ?? selectedPath?.split(RegExp(r'[/\\]')).last;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GlacierColors.border),
        boxShadow: glacierSoftShadow,
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Select File Button & Filename Pill
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlacierColors.darkForest,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                onPressed: loading ? null : pickFile,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('Select .nc Patch', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              if (fileName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: GlacierColors.pastelBlue,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description_rounded, size: 15, color: GlacierColors.pastelBlueText),
                      const SizedBox(width: 6),
                      Text(
                        fileName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GlacierColors.pastelBlueText),
                      ),
                    ],
                  ),
                )
              else
                const Text(
                  'No patch selected yet',
                  style: TextStyle(fontSize: 12, color: GlacierColors.textMuted),
                ),
            ],
          ),

          // Pixel size & Action Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pixel size pill
              Container(
                width: 130,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: GlacierColors.surfaceMuted.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    const Text('Pixel: ', style: TextStyle(fontSize: 11, color: GlacierColors.textSecondary)),
                    Expanded(
                      child: TextField(
                        controller: _pixelSizeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const Text('m', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GlacierColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Run inference button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlacierColors.sage,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                onPressed: (loading || (selectedPath == null && selectedFile == null))
                    ? null
                    : () => runPrediction(),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Run Model Inference', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsMetricsBanner() {
    final areaKm2 = (result!['glacier_area_km2'] as num?)?.toDouble();
    final fraction = (result!['glacier_fraction'] as num?)?.toDouble() ?? 0.0;
    final px = result!['glacier_pixels'] ?? 0;
    final metrics = result!['metrics'] as Map<String, dynamic>?;
    final dice = (metrics?['dice'] as num?)?.toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 36) / 4;

        return Row(
          children: [
            // Soft Sage Card: Glacier Area
            _pastelStatCard(
              title: 'Glacier Area',
              value: areaKm2 != null ? '${areaKm2.toStringAsFixed(2)} km²' : 'N/A',
              subtitle: areaKm2 != null ? '${(areaKm2 * 100).toStringAsFixed(1)} Hectares' : 'Set pixel resolution',
              bgColor: GlacierColors.pastelGreen,
              textColor: GlacierColors.pastelGreenText,
              icon: Icons.square_foot_rounded,
              width: itemWidth,
            ),
            const SizedBox(width: 12),

            // Soft Blue Card: Coverage Fraction
            _pastelStatCard(
              title: 'Glacier Coverage',
              value: '${(fraction * 100).toStringAsFixed(1)}%',
              subtitle: 'Patch Surface Ratio',
              bgColor: GlacierColors.pastelBlue,
              textColor: GlacierColors.pastelBlueText,
              icon: Icons.pie_chart_outline_rounded,
              width: itemWidth,
            ),
            const SizedBox(width: 12),

            // Soft Yellow Card: Glacier Pixels
            _pastelStatCard(
              title: 'Glacier Pixels',
              value: '$px px',
              subtitle: 'Positive Class (1)',
              bgColor: GlacierColors.pastelYellow,
              textColor: GlacierColors.pastelYellowText,
              icon: Icons.scatter_plot_rounded,
              width: itemWidth,
            ),
            const SizedBox(width: 12),

            // Soft Pink Card: Validation Dice
            _pastelStatCard(
              title: 'Evaluation Dice',
              value: dice != null ? '${(dice * 100).toStringAsFixed(1)}%' : 'Predicted',
              subtitle: dice != null ? 'Ground-Truth Match' : 'Unlabeled Patch',
              bgColor: GlacierColors.pastelPink,
              textColor: GlacierColors.pastelPinkText,
              icon: Icons.verified_outlined,
              width: itemWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _pastelStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
    required double width,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor.withValues(alpha: 0.8))),
                Icon(icon, size: 16, color: textColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.75))),
          ],
        ),
      ),
    );
  }

  Widget _buildTriViewGallery() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _viewCard(
          title: 'RGB True-Color (B4-B3-B2)',
          badge: 'Satellite',
          b64: result?['image_png'],
          defaultExportName: 'sentinel2_rgb.png',
        ),
        const SizedBox(width: 14),
        _viewCard(
          title: 'Glacier Segmentation Mask',
          badge: 'Predicted',
          b64: result?['mask_png'],
          defaultExportName: 'glacier_mask.png',
        ),
        const SizedBox(width: 14),
        _viewCard(
          title: 'Thermal Overlay Analysis',
          badge: 'Composite',
          b64: result?['overlay_png'],
          defaultExportName: 'glacier_overlay.png',
        ),
      ],
    );
  }

  Widget _viewCard({
    required String title,
    required String badge,
    required String? b64,
    required String defaultExportName,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: GlacierColors.border),
          boxShadow: glacierSoftShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PillBadge(
                  text: badge,
                  backgroundColor: GlacierColors.surfaceMuted,
                  textColor: GlacierColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Image Container
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: GlacierColors.surfaceMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GlacierColors.border.withValues(alpha: 0.5)),
                ),
                child: b64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          base64Decode(b64),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                        ),
                      )
                    : const Center(
                        child: Text('No preview available', style: TextStyle(color: GlacierColors.textMuted, fontSize: 12)),
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // Card Action Buttons
            if (b64 != null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GlacierColors.textPrimary,
                        side: const BorderSide(color: GlacierColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      onPressed: () => _showZoomDialog(title, b64),
                      icon: const Icon(Icons.zoom_in_rounded, size: 16),
                      label: const Text('Zoom View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlacierColors.darkForest,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      onPressed: () {
                        final key = defaultExportName.contains('rgb')
                            ? 'image_png'
                            : defaultExportName.contains('mask')
                                ? 'mask_png'
                                : 'overlay_png';
                        savePng(key, defaultExportName);
                      },
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Save PNG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCard(Map<String, dynamic> m) {
    final dice = (m['dice'] as num?)?.toDouble() ?? 0.0;
    final iou = (m['iou'] as num?)?.toDouble() ?? 0.0;
    final prec = (m['precision'] as num?)?.toDouble() ?? 0.0;
    final rec = (m['recall'] as num?)?.toDouble() ?? 0.0;
    final conf = m['confusion'] as Map<String, dynamic>?;

    return Container(
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
              const Text('Ground-Truth Segmentation Accuracy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary)),
              const PillBadge(
                text: 'Validated vs Reference Mask',
                backgroundColor: GlacierColors.pastelGreen,
                textColor: GlacierColors.pastelGreenText,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metricBar('Dice Score (F1)', dice),
              const SizedBox(width: 14),
              _metricBar('IoU (Jaccard)', iou),
              const SizedBox(width: 14),
              _metricBar('Precision', prec),
              const SizedBox(width: 14),
              _metricBar('Recall (Sensitivity)', rec),
            ],
          ),
          if (conf != null) ...[
            const Divider(height: 28, color: GlacierColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _confStat('True Positive', '${conf['tp']} px', const Color(0xFF16A34A)),
                _confStat('False Positive', '${conf['fp']} px', const Color(0xFFDC2626)),
                _confStat('False Negative', '${conf['fn']} px', const Color(0xFFEA580C)),
                _confStat('True Negative', '${conf['tn']} px', GlacierColors.textSecondary),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricBar(String label, double val) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: GlacierColors.textSecondary)),
              Text('${(val * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: val.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: GlacierColors.surfaceMuted,
              valueColor: const AlwaysStoppedAnimation(GlacierColors.sage),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confStat(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: GlacierColors.textSecondary)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GlacierColors.border),
        boxShadow: glacierSoftShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: GlacierColors.pastelGreen,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.terrain_rounded, size: 36, color: GlacierColors.sage),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Ready for Segmentation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GlacierColors.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Select any NetCDF (.nc) satellite patch from your dataset to begin deep learning segmentation.',
            style: TextStyle(fontSize: 13, color: GlacierColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlacierColors.darkForest,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                onPressed: pickFile,
                icon: const Icon(Icons.file_upload_outlined, size: 18),
                label: const Text('Choose .nc File', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GlacierColors.border),
        boxShadow: glacierSoftShadow,
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: GlacierColors.sage, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text(
            'Running DoubleConv U-Net Inference & Computing Glacier Boundaries...',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: GlacierColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlacierColors.pastelPink,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: GlacierColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(fontSize: 12, color: GlacierColors.pastelPinkText, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
