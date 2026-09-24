import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/note_models.dart';

class NoteAttachmentWidget extends StatelessWidget {
  final NoteFile file;

  const NoteAttachmentWidget({super.key, required this.file});

  Future<void> _openFile() async {
    final url = file.downloadUrl;
    if (url == null) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: _openFile,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (file.size != null)
                    Text(
                      '${(file.size! / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}