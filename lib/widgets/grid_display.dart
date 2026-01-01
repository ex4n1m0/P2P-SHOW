import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/grid_provider.dart';

class GridDisplay extends StatelessWidget {
  const GridDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GridProvider>(
      builder: (context, gridProvider, child) {
        final devices = gridProvider.devices;

        if (devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.devices,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No devices connected',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start location tracking and connect to peers',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return CustomPaint(
          painter: GridPainter(
            devices: devices,
            gridProvider: gridProvider,
          ),
          child: Container(),
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  final Map<String, dynamic> devices;
  final GridProvider gridProvider;

  GridPainter({
    required this.devices,
    required this.gridProvider,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final backgroundPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // Draw grid lines
    _drawGrid(canvas, size);

    // Draw devices
    for (var entry in devices.entries) {
      final deviceId = entry.key;
      final devicePosition = entry.value;
      final relativePos = gridProvider.getRelativePosition(deviceId);

      if (relativePos != null) {
        _drawDevice(
          canvas,
          size,
          relativePos,
          devicePosition.color,
          deviceId,
        );
      }
    }

    // Draw device count
    _drawDeviceCount(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridLines = 10;

    // Vertical lines
    for (int i = 0; i <= gridLines; i++) {
      final x = (size.width / gridLines) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Horizontal lines
    for (int i = 0; i <= gridLines; i++) {
      final y = (size.height / gridLines) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  void _drawDevice(
    Canvas canvas,
    Size size,
    Offset relativePosition,
    Color color,
    String deviceId,
  ) {
    final x = relativePosition.dx * size.width;
    final y = relativePosition.dy * size.height;

    // Calculate device size based on number of connected devices
    final deviceCount = devices.length;
    final baseSize = size.width / (deviceCount + 2);
    final deviceSize = baseSize.clamp(40.0, size.width / 3);

    // Draw device rectangle with border
    final deviceRect = Rect.fromCenter(
      center: Offset(x, y),
      width: deviceSize,
      height: deviceSize,
    );

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(
      deviceRect.shift(const Offset(2, 2)),
      shadowPaint,
    );

    // Draw main rectangle
    final devicePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(deviceRect, devicePaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(deviceRect, borderPaint);

    // Draw device ID text
    final textSpan = TextSpan(
      text: deviceId.substring(0, 8),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black,
            offset: Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        x - textPainter.width / 2,
        y + deviceSize / 2 + 8,
      ),
    );
  }

  void _drawDeviceCount(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: 'Devices: ${devices.length}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black,
            offset: Offset(1, 1),
            blurRadius: 3,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      const Offset(16, 16),
    );
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return true; // Always repaint for smooth updates
  }
}
