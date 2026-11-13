import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DeviceImageSelection {
  final List<int> bytes;
  final String contentType;

  const DeviceImageSelection({required this.bytes, required this.contentType});
}

Future<DeviceImageSelection?> pickDeviceImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Escolher do celular'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tirar uma foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
  if (file == null) return null;

  final contentType = _imageContentType(file);
  return DeviceImageSelection(
    bytes: await file.readAsBytes(),
    contentType: contentType,
  );
}

String _imageContentType(XFile file) {
  const supported = {'image/jpeg', 'image/png', 'image/webp', 'image/gif'};
  final mimeType = file.mimeType?.toLowerCase();
  if (mimeType != null && supported.contains(mimeType)) return mimeType;

  final extension = file.name.split('.').last.toLowerCase();
  return switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => throw const FormatException(
      'Formato não suportado. Use JPG, PNG, WEBP ou GIF.',
    ),
  };
}
