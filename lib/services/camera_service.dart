// services/camera_service.dart
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class CameraService {
  late CameraController _controller;
  final ImagePicker _picker = ImagePicker();

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    await _controller.initialize();
  }

  Future<XFile?> takePicture() async {
    return await _controller.takePicture();
  }

  Future<XFile?> pickImageFromGallery() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

  void dispose() {
    _controller.dispose();
  }
}
