import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FieldConfig {
  const FieldConfig(this.key, this.label,
      {this.keyboardType,
      this.maxLines = 1,
      this.options,
      this.isImagePicker = false});
  final String key;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final List<FieldOption>? options;
  final bool isImagePicker;
}

class FieldOption {
  const FieldOption({required this.value, required this.label});

  final String value;
  final String label;
}

Future<Map<String, String>?> showRecordDialog(
  BuildContext context, {
  required String title,
  required List<FieldConfig> fields,
  Map<String, dynamic> initialValues = const {},
}) {
  final controllers = {
    for (final field in fields)
      field.key: TextEditingController(
        text: initialValues[field.key]?.toString() ?? '',
      ),
  };
  final selectedImageBytes = <String, Uint8List>{};
  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Text(title),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(context).height * 0.62,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: field.isImagePicker
                        ? OutlinedButton.icon(
                            onPressed: () async {
                              final image = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1200,
                                imageQuality: 85,
                              );
                              if (image == null) return;
                              final bytes = await image.readAsBytes();
                              setDialogState(() {
                                controllers[field.key]!.text = image.path;
                                selectedImageBytes[field.key] = bytes;
                              });
                            },
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipOval(
                                  child: selectedImageBytes[field.key] == null
                                      ? Container(
                                          width: 46,
                                          height: 46,
                                          color: const Color(0xfffff0f5),
                                          child: const Icon(Icons.person_outline),
                                        )
                                      : Image.memory(
                                          selectedImageBytes[field.key]!,
                                          width: 46,
                                          height: 46,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  controllers[field.key]!.text.isEmpty
                                      ? field.label
                                      : 'Change profile image',
                                ),
                              ],
                            ),
                          )
                        : field.options == null
                        ? TextField(
                            controller: controllers[field.key]!,
                            keyboardType: field.keyboardType,
                            maxLines: field.maxLines,
                            decoration: InputDecoration(
                              labelText: field.label,
                              border: const OutlineInputBorder(),
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: controllers[field.key]!.text.isEmpty
                                ? null
                                : controllers[field.key]!.text,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: field.label,
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              for (final option in field.options!)
                                DropdownMenuItem(
                                  value: option.value,
                                  child: Text(option.label),
                                ),
                            ],
                            onChanged: (value) => setDialogState(
                              () => controllers[field.key]!.text = value ?? '',
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop(
                controllers
                    .map((key, value) => MapEntry(key, value.text.trim())),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
  });
}
