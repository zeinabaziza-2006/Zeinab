import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/khatwa_store.dart';

class FootPhotoPage extends StatefulWidget {
  final String language;

  const FootPhotoPage({
    super.key,
    required this.language,
  });

  @override
  State<FootPhotoPage> createState() => _FootPhotoPageState();
}

class _FootPhotoPageState extends State<FootPhotoPage> {
  final store = KhatwaStore.instance;
  final ImagePicker picker = ImagePicker();

  bool loading = false;

  bool get rtl =>
      widget.language == 'العربية' ||
      widget.language == 'تونسي';

  String text(
    String en,
    String fr,
    String ar,
    String tn,
  ) {
    switch (widget.language) {
      case 'Français':
        return fr;
      case 'العربية':
        return ar;
      case 'تونسي':
        return tn;
      default:
        return en;
    }
  }

  Future<void> pickPhoto(ImageSource source) async {
    setState(() {
      loading = true;
    });

    try {
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 75,
      );

      if (file == null) {
        setState(() {
          loading = false;
        });
        return;
      }

      final bytes = await file.readAsBytes();
      final extension = file.name.toLowerCase().split('.').last;

      String mimeType = 'image/jpeg';

      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      }

      final base64Image = base64Encode(bytes);

      await store.addEntry({
        'type': 'foot_photo',
        'base64': base64Image,
        'mimeType': mimeType,
        'fileName': file.name,
        'date': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text(
              'Photo saved successfully.',
              'Photo enregistrée avec succès.',
              'تم حفظ الصورة بنجاح.',
              'التصويرة تسجلت بنجاح.',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save photo: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Widget photoWidget(Map<String, dynamic> entry) {
    final base64Image = entry['base64']?.toString() ?? '';

    if (base64Image.isEmpty) {
      return const Center(
        child: Icon(
          Icons.broken_image,
          size: 45,
        ),
      );
    }

    try {
      return Image.memory(
        base64Decode(base64Image),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 220,
      );
    } catch (_) {
      return const Center(
        child: Icon(
          Icons.broken_image,
          size: 45,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: rtl
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text(
              'Foot Photos',
              'Photos du pied',
              'صور القدم',
              'تصاور الساق',
            ),
          ),
        ),
        body: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final photos = store.photoEntries();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          const Text(
                            '📸',
                            style: TextStyle(fontSize: 55),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            text(
                              'Save pictures of your feet for monitoring.',
                              'Enregistrez des photos de vos pieds pour le suivi.',
                              'احفظ صور قدميك للمتابعة.',
                              'احفظ تصاور ساقيك للمتابعة.',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          if (loading)
                            const CircularProgressIndicator()
                          else
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                FilledButton.icon(
                                  onPressed: () {
                                    pickPhoto(ImageSource.camera);
                                  },
                                  icon: const Icon(Icons.camera_alt),
                                  label: Text(
                                    text(
                                      'Camera',
                                      'Caméra',
                                      'الكاميرا',
                                      'الكاميرا',
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    pickPhoto(ImageSource.gallery);
                                  },
                                  icon: const Icon(
                                    Icons.photo_library,
                                  ),
                                  label: Text(
                                    text(
                                      'Gallery',
                                      'Galerie',
                                      'المعرض',
                                      'المعرض',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (photos.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          text(
                            'No saved photos yet.',
                            'Aucune photo enregistrée.',
                            'لا توجد صور محفوظة بعد.',
                            'ما فماش تصاور محفوظة توة.',
                          ),
                        ),
                      ),
                    ),
                  ...photos.reversed.map(
                    (photo) => Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          photoWidget(photo),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              photo['date']?.toString() ?? '',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}