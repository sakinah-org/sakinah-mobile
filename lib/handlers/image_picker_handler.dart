import 'dart:io';
import 'package:sakinah/configurations/app_errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerHandler {
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the given source (gallery or camera)
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } on PlatformException catch (e) {
      final code = e.code;
      final message = switch (code) {
        'camera_access_denied' =>
          'Camera permission denied. Please enable it from settings.',
        'photo_access_denied' =>
          'Photos permission denied. Please enable it from settings.',
        'multiple_request' => 'Another image picking request is in progress.',
        'invalid_image' => 'Selected file is not a valid image.',
        _ => e.message ?? 'Unable to pick image.',
      };
      final failure = ImagePickerFailure(
        message,
        code: code,
      );
      throw failure;
    } catch (e) {
      throw UnknownFailure(
          'An unexpected error occurred while selecting an image. Please try again.');
    }
    return null;
  }

  /// Shows a modal bottom sheet to ask user for source (gallery or camera)
  Future<File?> showImageSourcePickerBottomsheet(BuildContext context) async {
    return showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  final image = await pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  final image = await pickImage(source: ImageSource.camera);
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
