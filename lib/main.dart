import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'dart:io';

// --- Global Variables (Initialize in main()) ---
late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Request available cameras before running the app
  cameras = await availableCameras();
  runApp(const ObjectTrackerApp());
}

// --- Transformation/Tracking Data Model ---
class TrackedObject {
  final int trackingId;
  Rect boundingBox;
  Offset center;
  double width;
  double height;
  String transformation = 'None';
  String label = 'Unknown'; 
  
  TrackedObject(this.trackingId, this.boundingBox)
      : center = boundingBox.center,
        width = boundingBox.width,
        height = boundingBox.height;
}

// --- Main App Widget ---
class ObjectTrackerApp extends StatelessWidget {
  const ObjectTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ObjectTrackerScreen(),
    );
  }
}

class ObjectTrackerScreen extends StatefulWidget {
  const ObjectTrackerScreen({super.key});

  @override
  ObjectTrackerScreenState createState() => ObjectTrackerScreenState();
}

class ObjectTrackerScreenState extends State<ObjectTrackerScreen> {
  late CameraController _controller;
  late ObjectDetector _objectDetector;
  final Map<int, TrackedObject> _trackedObjects = {};
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeDetector();
  }

  // --- Initialization ---

  void _initializeDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,

    );
    _objectDetector = ObjectDetector(options: options);
  }

  void _initializeCamera() async {
    // Check if any camera is available
    if (cameras.isEmpty) {
      if (kDebugMode) {
        print("No cameras available!");
      }
      if (mounted) {
        setState(() {});
      }
      return;
    }
    
    _controller = CameraController(
      cameras.first, // Use the first available camera (usually rear)
      ResolutionPreset.medium, // Using medium for better balance and compatibility
      enableAudio: false,
    );
    
    try {
      await _controller.initialize();
      // Start streaming images for continuous detection
      await _controller.startImageStream(_processCameraImage);
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing camera: $e");
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  // --- Core Image Processing Logic (Cross-Platform Fix) ---

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || !mounted) return;
    _isBusy = true;

    // 1. Determine the image format based on the platform
    final InputImageFormat imageFormat;
    if (Platform.isIOS) {
      // iOS typically uses BGRA8888
      imageFormat = InputImageFormat.bgra8888;
    } else if (Platform.isAndroid) {
      // Android typically uses NV21
      imageFormat = InputImageFormat.nv21;
    } else {
      _isBusy = false;
      return;
    }

    // 2. Prepare the byte buffer (CRUCIAL FIX)
    Uint8List bytes;
    
    if (Platform.isAndroid) {
      // Android (NV21/YUV): Combine the three planes (Y, U, V) into one buffer.
      final int ySize = image.planes[0].bytes.length;
      final int uvSize = image.planes[1].bytes.length + image.planes[2].bytes.length;
      
      bytes = Uint8List(ySize + uvSize);
      
      // Copy Y plane (plane 0)
      bytes.setRange(0, ySize, image.planes[0].bytes);
      
      // Copy UV planes (plane 1 and 2) contiguously
      // This is necessary for the native ML Kit Android processor
      bytes.setRange(ySize, ySize + uvSize, 
          image.planes[1].bytes.followedBy(image.planes[2].bytes));
          
    } else if (Platform.isIOS) {
      // iOS (BGRA8888): Simply use the bytes from the first plane.
      bytes = image.planes.first.bytes;
    } else {
      _isBusy = false;
      return;
    }

    // 3. Prepare Metadata
    final InputImageMetadata metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: InputImageRotation.rotation90deg, 
      format: imageFormat, 
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    // 4. Create InputImage and Process
    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );

    try {
      final List<DetectedObject> detectedObjects = await _objectDetector.processImage(inputImage);

      // Analyze Transformations
      if (mounted) {
        setState(() {
          _analyzeTransformations(detectedObjects);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("ML Kit Detection Error: $e");
      }
    }


    _isBusy = false;
  }

  // --- Transformation and Label Analysis Function ---

  void _analyzeTransformations(List<DetectedObject> currentObjects) {
    // 1. Clear non-visible objects
    final Set<int> currentIds = currentObjects.map((obj) => obj.trackingId!).toSet();
    _trackedObjects.keys.toList().where((id) => !currentIds.contains(id)).forEach(_trackedObjects.remove);

    for (final currentObject in currentObjects) {
      final int id = currentObject.trackingId!;
      final Rect currentRect = currentObject.boundingBox;
      
      // Extract the label (taking the most confident one)
      String objectLabel = 'Unknown';
      if (currentObject.labels.isNotEmpty) {
        final label = currentObject.labels.first;
        objectLabel = '${label.text} (${(label.confidence * 100).toStringAsFixed(0)}%)';
      }

      if (_trackedObjects.containsKey(id)) {
        // Object was seen in the previous frame - Analyze Change!
        final TrackedObject previous = _trackedObjects[id]!;
        final Offset currentCenter = currentRect.center;

        // A. Translation (Movement): Check for significant center shift
        final double deltaX = (currentCenter.dx - previous.center.dx).abs();
        final double deltaY = (currentCenter.dy - previous.center.dy).abs();
        
        // B. Scaling (Size Change): Check for significant width change ratio
        final double scaleChange = currentRect.width / previous.width;

        // C. Determine Transformation (Thresholds need tuning)
        String transformation = 'Static';
        if (deltaX > 25 || deltaY > 25) {
          transformation = 'Moving';
        } else if (scaleChange > 1.1 || scaleChange < 0.9) {
          transformation = 'Scaling (${scaleChange > 1.0 ? 'Growing' : 'Shrinking'})';
        }
        
        // Update the tracked object for the next frame
        previous.boundingBox = currentRect;
        previous.center = currentCenter;
        previous.width = currentRect.width;
        previous.height = currentRect.height;
        previous.transformation = transformation;
        previous.label = objectLabel;

      } else {
        // New object detected - Initialize tracking
        _trackedObjects[id] = TrackedObject(id, currentRect);
        _trackedObjects[id]!.transformation = 'New Object';
        _trackedObjects[id]!.label = objectLabel;
      }
    }
  }
  
  // --- UI and Cleanup ---

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final size = MediaQuery.of(context).size;
    // Calculate scale factor to map ML Kit output (based on image size) to screen size
    final double scaleFactor = size.width / _controller.value.previewSize!.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Object Transformation Tracker')),
      body: Stack(
        children: [
          // Camera View (Background)
          SizedBox(
            width: size.width,
            height: size.height,
            child: CameraPreview(_controller),
          ),
          
          // Custom Painter (Foreground)
          CustomPaint(
            size: size,
            painter: TransformationPainter(
              objects: _trackedObjects.values.toList(),
              scaleFactor: scaleFactor, 
            ),
          ),

          // Transformation List
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 150,
              color: Colors.black.withOpacity(0.6),
              child: ListView.builder(
                itemCount: _trackedObjects.length,
                itemBuilder: (context, index) {
                  final obj = _trackedObjects.values.toList()[index];
                  return ListTile(
                    dense: true,
                    leading: Text('ID ${obj.trackingId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    title: Text(
                      'Label: ${obj.label}',
                      style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Status: ${obj.transformation}',
                      style: const TextStyle(color: Colors.yellow, fontSize: 14),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.stopImageStream();
    _controller.dispose();
    _objectDetector.close();
    super.dispose();
  }
}

// --- Custom Painter for Drawing Boxes and Transformation Text ---

class TransformationPainter extends CustomPainter {
  final List<TrackedObject> objects;
  final double scaleFactor;

  TransformationPainter({required this.objects, required this.scaleFactor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint boxPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final obj in objects) {
      // Scale coordinates from ML Kit output size to current screen size
      final Rect scaledRect = Rect.fromLTRB(
        obj.boundingBox.left * scaleFactor,
        obj.boundingBox.top * scaleFactor,
        obj.boundingBox.right * scaleFactor,
        obj.boundingBox.bottom * scaleFactor,
      );

      // 1. Draw Bounding Box
      canvas.drawRect(scaledRect, boxPaint);

      // 2. Draw Transformation Text (Label + Transformation)
      final displayText = '${obj.label} | ${obj.transformation}';
      
      textPainter.text = TextSpan(
        text: displayText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.indigo, // Added background for better visibility
        ),
      );
      textPainter.layout();
      
      // Position the text above the box
      textPainter.paint(canvas, Offset(scaledRect.left + 5, scaledRect.top - 25));
    }
  }

  @override
  bool shouldRepaint(covariant TransformationPainter oldDelegate) {
    // Only repaint if data has changed
    return oldDelegate.objects.length != objects.length || oldDelegate.objects.any((obj) {
      final newObj = objects.firstWhere((e) => e.trackingId == obj.trackingId, orElse: () => obj);
      return newObj.boundingBox != obj.boundingBox || newObj.transformation != obj.transformation || newObj.label != obj.label;
    });
  }
}