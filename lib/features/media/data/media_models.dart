// lib/features/media/data/media_models.dart

class MediaItem {
  final int id;
  final String title;
  final String alt;
  final String caption;
  final String description;
  final String mime;
  final String type; // image, video, audio, file
  final String url;
  final String link;
  final DateTime date;
  final DateTime modified;
  final String size; // فرمت شده مثل "123 KB"
  final int bytes;
  final int? width;
  final int? height;

  MediaItem({
    required this.id,
    required this.title,
    required this.alt,
    required this.caption,
    required this.description,
    required this.mime,
    required this.type,
    required this.url,
    required this.link,
    required this.date,
    required this.modified,
    required this.size,
    required this.bytes,
    this.width,
    this.height,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    // استخراج نوع فایل از mime type
    final mime = json['mime_type'] ?? '';
    String type = 'file';
    if (mime.startsWith('image/')) type = 'image';
    else if (mime.startsWith('video/')) type = 'video';
    else if (mime.startsWith('audio/')) type = 'audio';

    // استخراج اطلاعات اندازه
    final details = json['media_details'] ?? {};
    final width = details['width'] as int?;
    final height = details['height'] as int?;
    final filesize = details['filesize'] as int? ?? 0;
    String sizeStr = '—';
    if (filesize > 0) {
      if (filesize < 1024) sizeStr = '$filesize B';
      else if (filesize < 1024 * 1024) sizeStr = '${(filesize / 1024).toStringAsFixed(1)} KB';
      else sizeStr = '${(filesize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return MediaItem(
      id: json['id'] ?? 0,
      title: json['title']?['rendered']?.toString() ?? json['title']?.toString() ?? 'بدون عنوان',
      alt: json['alt_text']?.toString() ?? '',
      caption: json['caption']?['rendered']?.toString() ?? '',
      description: json['description']?['rendered']?.toString() ?? '',
      mime: mime,
      type: type,
      url: json['source_url'] ?? json['guid']?['rendered'] ?? '',
      link: json['link'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      modified: DateTime.tryParse(json['modified'] ?? '') ?? DateTime.now(),
      size: sizeStr,
      bytes: filesize,
      width: width,
      height: height,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'alt_text': alt,
      'caption': caption,
      'description': description,
      'mime_type': mime,
      'source_url': url,
      'link': link,
      'date': date.toIso8601String(),
      'modified': modified.toIso8601String(),
      'media_details': {
        'width': width,
        'height': height,
        'filesize': bytes,
      },
    };
  }
}

/// مدل پاسخ آپلود
class MediaUploadResponse {
  final int id;
  final String url;
  final String title;

  MediaUploadResponse({
    required this.id,
    required this.url,
    required this.title,
  });

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) {
    return MediaUploadResponse(
      id: json['id'] ?? 0,
      url: json['source_url'] ?? json['guid']?['rendered'] ?? '',
      title: json['title']?['rendered'] ?? json['title']?.toString() ?? '',
    );
  }
}