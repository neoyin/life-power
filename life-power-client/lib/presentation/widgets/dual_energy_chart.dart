import 'dart:ui' show TextDirection;
import 'package:flutter/material.dart';
import 'package:life_power_client/data/models/energy.dart';
import 'package:intl/intl.dart' hide TextDirection;

class DualEnergyChart extends StatefulWidget {
  final EnergyHistory myHistory;
  final EnergyHistory? otherHistory;

  const DualEnergyChart({
    super.key,
    required this.myHistory,
    this.otherHistory,
  });

  @override
  State<DualEnergyChart> createState() => _DualEnergyChartState();
}

class _DualEnergyChartState extends State<DualEnergyChart> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
    final mySnapshots = widget.myHistory.snapshots.length > 72
        ? widget.myHistory.snapshots.sublist(widget.myHistory.snapshots.length - 72)
        : widget.myHistory.snapshots;

    List<EnergySnapshot>? otherSnapshots;
    if (widget.otherHistory != null) {
      otherSnapshots = widget.otherHistory!.snapshots.length > 72
          ? widget.otherHistory!.snapshots.sublist(widget.otherHistory!.snapshots.length - 72)
          : widget.otherHistory!.snapshots;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final pointWidth = (screenWidth - 40) / 7;
        final myCount = mySnapshots.length;
        final otherCount = otherSnapshots?.length ?? 0;
        final maxCount = myCount > otherCount ? myCount : otherCount;
        final totalWidth = pointWidth * (maxCount - 1).clamp(6, 71);

        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 30, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 35,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var val in [100, 75, 50, 25, 0])
                      Text(
                        '$val',
                        style: const TextStyle(
                            color: Color(0xFF727d7e), fontSize: 10),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: totalWidth < (screenWidth - 40)
                        ? (screenWidth - 40)
                        : totalWidth,
                    child: CustomPaint(
                      painter: DualEnergyChartPainter(
                        mySnapshots: mySnapshots,
                        otherSnapshots: otherSnapshots,
                        myPrimaryColor: const Color(0xFF535f6f),
                        mySecondaryColor: const Color(0xFFd7e3f7),
                        otherPrimaryColor: const Color(0xFF006f1d),
                        otherSecondaryColor: const Color(0xFFa8e6cf),
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

class DualEnergyChartPainter extends CustomPainter {
  final List<EnergySnapshot> mySnapshots;
  final List<EnergySnapshot>? otherSnapshots;
  final Color myPrimaryColor;
  final Color mySecondaryColor;
  final Color otherPrimaryColor;
  final Color otherSecondaryColor;

  DualEnergyChartPainter({
    required this.mySnapshots,
    this.otherSnapshots,
    required this.myPrimaryColor,
    required this.mySecondaryColor,
    required this.otherPrimaryColor,
    required this.otherSecondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGridLines(canvas, size);

    _drawLine(canvas, size, mySnapshots, myPrimaryColor, mySecondaryColor, true);

    if (otherSnapshots != null && otherSnapshots!.isNotEmpty) {
      _drawLine(canvas, size, otherSnapshots!, otherPrimaryColor, otherSecondaryColor, false);
    }

    _drawXLabels(canvas, size, mySnapshots);
  }

  void _drawLine(Canvas canvas, Size size, List<EnergySnapshot> snapshots, Color primaryColor, Color secondaryColor, bool isMyLine) {
    if (snapshots.isEmpty) return;

    final int count = snapshots.length;
    final double stepX = count > 1 ? size.width / (count - 1) : size.width;

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (int i = 0; i < count; i++) {
      final snapshot = snapshots[i];
      final x = i * stepX;
      final y = size.height - (snapshot.score / 100.0 * size.height);
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
        final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p2.dx,
          p2.dy,
        );
        fillPath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p2.dx,
          p2.dy,
        );
      }
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();
    }

    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = isMyLine ? 3 : 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withOpacity(isMyLine ? 0.3 : 0.2),
          primaryColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    for (int i = 0; i < points.length; i++) {
      final pointPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;

      final pointBorderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(points[i], isMyLine ? 4 : 3, pointPaint);
      canvas.drawCircle(points[i], isMyLine ? 4 : 3, pointBorderPaint);
    }
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

  void _drawXLabels(Canvas canvas, Size size, List<EnergySnapshot> snapshots) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    int skip = snapshots.length > 20 ? 6 : 2;
    if (snapshots.length <= 10) skip = 1;

    final double stepX = snapshots.length > 1 ? size.width / (snapshots.length - 1) : size.width;

    for (int i = 0; i < snapshots.length; i++) {
      if (i % skip != 0 && i != snapshots.length - 1) continue;

      final x = i * stepX;
      final date = snapshots[i].createdAt.toLocal();

      final label = DateFormat('MM/dd').format(date) +
          '\n' +
          DateFormat('HH:mm').format(date);

      textPainter.textAlign = TextAlign.center;
      textPainter.text = TextSpan(
        text: label,
        style:
            const TextStyle(color: Color(0xFF727d7e), fontSize: 9, height: 1.2),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, size.height + 10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}