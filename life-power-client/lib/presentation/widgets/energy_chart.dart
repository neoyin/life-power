import 'dart:ui' show TextDirection;
import 'package:flutter/material.dart';
import 'package:life_power_client/data/models/energy.dart';
import 'package:intl/intl.dart' hide TextDirection;

class EnergyChart extends StatefulWidget {
  final EnergyHistory history;

  const EnergyChart({super.key, required this.history});

  @override
  State<EnergyChart> createState() => _EnergyChartState();
}

class _EnergyChartState extends State<EnergyChart> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Scroll to the end after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Limit to 72 points
    final snapshots = widget.history.snapshots.length > 72 
        ? widget.history.snapshots.sublist(widget.history.snapshots.length - 72)
        : widget.history.snapshots;
    
    final limitedHistory = EnergyHistory(snapshots: snapshots);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        // 10 points per screen or at least enough for visible items
        final pointWidth = (screenWidth - 40) / 7; // show 7 items at once
        final totalWidth = pointWidth * (snapshots.length - 1).clamp(6, 71);
        final chartHeight = constraints.maxHeight;

        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 30, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fixed Y-Axis Labels
              SizedBox(
                width: 35,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var val in [100, 75, 50, 25, 0])
                      Text(
                        '$val',
                        style: const TextStyle(color: Color(0xFF727d7e), fontSize: 10),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Scrollable Chart Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: totalWidth < (screenWidth - 40) ? (screenWidth - 40) : totalWidth,
                    child: CustomPaint(
                      painter: EnergyChartPainter(
                        history: limitedHistory,
                        primaryColor: const Color(0xFF535f6f),
                        secondaryColor: const Color(0xFFd7e3f7),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class EnergyChartPainter extends CustomPainter {
  final EnergyHistory history;
  final Color primaryColor;
  final Color secondaryColor;

  EnergyChartPainter({
    required this.history,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.snapshots.isEmpty) return;

    final double height = size.height;
    final double width = size.width;
    final int count = history.snapshots.length;
    final double stepX = count > 1 ? width / (count - 1) : width;

    // Draw horizontal grid lines
    _drawGridLines(canvas, size);

    // Prepare paths
    final path = Path();
    final fillPath = Path();

    final points = <Offset>[];
    final colors = <Color>[];
    final stops = <double>[];

    for (int i = 0; i < count; i++) {
      final snapshot = history.snapshots[i];
      final x = i * stepX;
      final y = height - (snapshot.score / 100.0 * height);
      points.add(Offset(x, y));
      
      // Dynamic colors
      colors.add(_getScoreColor(snapshot.score));
      stops.add(i / (count - 1).clamp(1, count));
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
        final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
        
        path.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          p2.dx, p2.dy,
        );
        fillPath.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          p2.dx, p2.dy,
        );
      }
      fillPath.lineTo(points.last.dx, height);
      fillPath.close();
    }

    final gradient = LinearGradient(
      colors: colors.length > 1 ? colors : [colors[0], colors[0]],
      stops: stops.length > 1 ? stops : [0.0, 1.0],
    ).createShader(Rect.fromLTRB(0, 0, width, height));

    final paint = Paint()
      ..shader = gradient
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _getScoreColor(history.snapshots.last.score).withOpacity(0.3),
          _getScoreColor(history.snapshots.last.score).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, width, height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw points
    for (int i = 0; i < points.length; i++) {
      final pointPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      
      final pointBorderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
        
      canvas.drawCircle(points[i], 4, pointPaint);
      canvas.drawCircle(points[i], 4, pointBorderPaint);
    }
    
    // Draw X-axis labels
    _drawXLabels(canvas, size, stepX);
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return const Color(0xFF006f1d);
    if (score >= 40) return const Color(0xFFfec330);
    return const Color(0xFF9f403d);
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFd9e5e6).withOpacity(0.5)
      ..strokeWidth = 1;

    final values = [100, 75, 50, 25, 0];

    for (var val in values) {
      final y = size.height - (val / 100.0 * size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawXLabels(Canvas canvas, Size size, double stepX) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    int skip = history.snapshots.length > 20 ? 6 : 2;
    if (history.snapshots.length <= 10) skip = 1;

    for (int i = 0; i < history.snapshots.length; i++) {
      if (i % skip != 0 && i != history.snapshots.length - 1) continue;

      final x = i * stepX;
      final date = history.snapshots[i].createdAt.toLocal();
      
      final label = DateFormat('MM/dd').format(date) + '\n' + DateFormat('HH:mm').format(date);
      
      textPainter.textAlign = TextAlign.center;
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Color(0xFF727d7e), fontSize: 9, height: 1.2),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height + 10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
