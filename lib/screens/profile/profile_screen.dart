import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/supabase_service.dart';
import '../../widgets/page_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;

  Future<void> _pickAndUploadImage() async {
    final employee = EmployeeSession.current;
    if (employee == null || employee['id'] == null) return;

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _uploading = true);
    try {
      final publicUrl = await hrRepository.uploadEmployeeProfileImage(
        employeeId: employee['id'],
        bytes: await image.readAsBytes(),
        fileName: image.name,
      );
      if (!mounted) return;
      EmployeeSession.notifier.value = {
        ...employee,
        'profile_image': publicUrl,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปโหลดรูปโปรไฟล์เรียบร้อย')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถอัปโหลดรูปโปรไฟล์ได้')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employee = EmployeeSession.current;
    final fullName =
        '${employee?['first_name'] ?? ''} ${employee?['last_name'] ?? ''}'
            .trim();

    return HrPage(
      title: 'Profile',
      subtitle: 'Current employee session',
      child: ListView(
        children: [
          if (!SupabaseService.isConfigured) const ConfigBanner(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _ProfileAvatar(imageUrl: employee?['profile_image']?.toString()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isEmpty ? 'Demo User' : fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          employee == null
                              ? 'No employee session'
                              : '${employee['employee_code'] ?? '-'} - ${employee['email'] ?? '-'}',
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: employee == null || _uploading
                        ? null
                        : _pickAndUploadImage,
                    icon: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_camera_outlined),
                    tooltip: 'เปลี่ยนรูปโปรไฟล์',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const CircleAvatar(
        radius: 34,
        child: Icon(Icons.person_outline, size: 34),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: 68,
        height: 68,
        fit: BoxFit.cover,
        placeholder: (_, __) => const SizedBox(
          width: 68,
          height: 68,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => const CircleAvatar(
          radius: 34,
          child: Icon(Icons.person_outline, size: 34),
        ),
      ),
    );
  }
}
