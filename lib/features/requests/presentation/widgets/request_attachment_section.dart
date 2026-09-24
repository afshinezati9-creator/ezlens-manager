import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/request_models.dart';

class RequestAttachmentSection extends StatelessWidget {
  final List<RequestAttachment> files;

  const RequestAttachmentSection({super.key, required this.files});

  // ===== دانلود برای وب (باز کردن در تب جدید) =====
  Future<void> _downloadWeb(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('لینک قابل باز کردن نیست');
    }
  }

  // ===== دانلود برای اندروید =====
  Future<void> _downloadAndroid(BuildContext context, RequestAttachment file) async {
    final url = file.downloadUrl;
    if (url == null) {
      _showSnackBar(context, '❌ آدرس فایل معتبر نیست');
      return;
    }

    if (await Permission.storage.request().isGranted == false) {
      _showSnackBar(context, '⚠️ مجوز ذخیره‌سازی لازم است');
      return;
    }

    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        _showSnackBar(context, '❌ دسترسی به پوشه دانلود ممکن نیست');
        return;
      }

      final fileName = file.name.isNotEmpty ? file.name : 'download_${DateTime.now().millisecondsSinceEpoch}.file';
      final savePath = '${directory.path}/$fileName';

      final dio = Dio();
      await dio.download(url, savePath, onReceiveProgress: (received, total) {
        // می‌توانید پیشرفت را نمایش دهید
      });

      await OpenFile.open(savePath);
      _showSnackBar(context, '✅ فایل دانلود شد: $savePath');
    } catch (e) {
      _showSnackBar(context, '❌ خطا در دانلود: $e');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  // ===== تابع اصلی دانلود (تشخیص پلتفرم) =====
  Future<void> _downloadFile(BuildContext context, RequestAttachment file) async {
    final url = file.downloadUrl;
    if (url == null) {
      _showSnackBar(context, '❌ آدرس فایل معتبر نیست');
      return;
    }

    if (kIsWeb) {
      // ===== اگر روی وب هستیم، لینک را در تب جدید باز کن =====
      await _downloadWeb(url);
    } else {
      // ===== اگر روی اندروید هستیم، دانلود کن =====
      await _downloadAndroid(context, file);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, size: 20),
                const SizedBox(width: 8),
                Text(
                  'فایل‌های پیوست (${files.length})',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...files.map((file) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, size: 24, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          if (file.size != null)
                            Text(
                              '${(file.size! / 1024).toStringAsFixed(1)} KB',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_outlined, color: Colors.blue),
                      onPressed: () => _downloadFile(context, file),
                      tooltip: 'دانلود فایل',
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}