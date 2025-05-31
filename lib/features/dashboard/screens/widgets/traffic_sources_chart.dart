// lib/features/dashboard/widgets/traffic_sources_chart.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

class TrafficSourcesChart extends StatelessWidget {
  final Map<String, int> sourceBreakdown;

  const TrafficSourcesChart({
    Key? key,
    required this.sourceBreakdown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.brightness == Brightness.dark 
              ? Colors.grey[800]! 
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Traffic Sources',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.pie_chart,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            if (sourceBreakdown.isEmpty)
              _buildEmptyState(context)
            else
              _buildChart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.traffic_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No traffic data yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Traffic source breakdown will appear here once visitors start accessing your review page',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final theme = Theme.of(context);
    final total = sourceBreakdown.values.fold(0, (sum, count) => sum + count);
    
    if (total == 0) return _buildEmptyState(context);
    
    // Convert to list and sort by count
    final sources = sourceBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Row(
      children: [
        // Pie chart
        Expanded(
          flex: 2,
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: PieChartPainter(
                sources: sources,
                total: total,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 24),
        
        // Legend
        Expanded(
          flex: 3,
          child: Column(
            children: sources.map((entry) {
              final percentage = (entry.value / total * 100);
              final color = _getSourceColor(entry.key);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getSourceDisplayName(entry.key),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${entry.value} visits (${percentage.toStringAsFixed(1)}%)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'qr':
        return Colors.purple;
      case 'email':
        return Colors.blue;
      case 'direct':
        return Colors.green;
      case 'link':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getSourceDisplayName(String source) {
    switch (source.toLowerCase()) {
      case 'qr':
        return 'QR Code Scans';
      case 'email':
        return 'Email Links';
      case 'direct':
        return 'Direct Access';
      case 'link':
        return 'Shared Links';
      default:
        return source.toUpperCase();
    }
  }
}

class PieChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> sources;
  final int total;

  PieChartPainter({
    required this.sources,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    
    double startAngle = -math.pi / 2; // Start from top
    
    for (final source in sources) {
      final sweepAngle = (source.value / total) * 2 * math.pi;
      final color = _getSourceColor(source.key);
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'qr':
        return Colors.purple;
      case 'email':
        return Colors.blue;
      case 'direct':
        return Colors.green;
      case 'link':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}