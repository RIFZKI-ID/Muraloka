import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:muraloka/all_code/data_api/canvas_artwork_repository.dart';

class RenderedImageDialog extends StatefulWidget {
  final Future<Uint8List?> imageFuture;

  const RenderedImageDialog({Key? key, required this.imageFuture})
      : super(key: key);

  @override
  State<RenderedImageDialog> createState() => _RenderedImageDialogState();
}

class _RenderedImageDialogState extends State<RenderedImageDialog> {
  final CanvasArtworkRepository _repository = CanvasArtworkRepository();
  bool _isLoading = false;

  /// Save image to device storage
  Future<void> _saveToDevice(Uint8List imageData) async {
    setState(() => _isLoading = true);

    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Create file in cache directory first (safe for sharing)
      final cacheDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'muraloka_$timestamp.png';
      final tempFile = File('${cacheDir.path}/$fileName');
      
      // Write image data to temp file
      await tempFile.writeAsBytes(imageData);

      // Try to copy to Pictures folder for permanent storage
      Directory? picturesDir;
      File? permanentFile;
      
      try {
        if (Platform.isAndroid) {
          // Try to save to public Pictures directory
          final picturePath = '/storage/emulated/0/Pictures/Muraloka';
          picturesDir = Directory(picturePath);
          if (!await picturesDir.exists()) {
            await picturesDir.create(recursive: true);
          }
          permanentFile = File('${picturesDir.path}/$fileName');
          await permanentFile.writeAsBytes(imageData);
        } else if (Platform.isIOS) {
          picturesDir = await getApplicationDocumentsDirectory();
          permanentFile = File('${picturesDir.path}/$fileName');
          await permanentFile.writeAsBytes(imageData);
        }
      } catch (e) {
        debugPrint('Could not save to permanent location: $e');
        // Continue with temp file for sharing
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              permanentFile != null
                  ? 'Image saved to ${permanentFile.path}'
                  : 'Image ready to share',
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () => _shareImage(tempFile),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Share image using share_plus
  Future<void> _shareImage(File imageFile) async {
    try {
      // For Android, use content URI via FileProvider
      final xFile = XFile(imageFile.path);
      
      // Share with proper MIME type
      await Share.shareXFiles(
        [xFile],
        text: 'Created with Muraloka 🎨',
        subject: 'My Muraloka Artwork',
      );
    } catch (e) {
      debugPrint('Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Save image to Firestore as base64
  Future<void> _saveToFirestore(Uint8List imageData) async {
    setState(() => _isLoading = true);

    try {
      // Convert image to base64
      final base64Image = base64Encode(imageData);

      // Get metadata
      final metadata = {
        'format': 'png',
        'size': imageData.length,
        'width': 0, // Could be extracted if needed
        'height': 0, // Could be extracted if needed
      };

      // Save to Firestore
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final title = 'Canvas Art $timestamp';
      
      final artworkId = await _repository.create(
        title: title,
        imageDataBase64: base64Image,
        metadata: metadata,
      );

      if (artworkId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Canvas saved to Firestore successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save canvas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving to Firestore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Rendered Image"),
      content: FutureBuilder<Uint8List?>(
        future: widget.imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 50,
              child: Center(child: CircularProgressIndicator.adaptive()),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox();
          }
          return InteractiveViewer(
            maxScale: 10,
            child: Image.memory(snapshot.data!),
          );
        },
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Discard'),
          ),
        ),
        FutureBuilder<Uint8List?>(
          future: widget.imageFuture,
          builder: (context, snapshot) {
            final imageData = snapshot.data;
            return Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || imageData == null
                        ? null
                        : () => _saveToDevice(imageData),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download),
                    label: const Text('Save to Device'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || imageData == null
                        ? null
                        : () => _saveToFirestore(imageData),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: const Text('Save to Firestore'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
