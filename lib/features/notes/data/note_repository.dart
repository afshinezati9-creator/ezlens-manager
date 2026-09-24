import 'dart:io';
import 'package:dio/dio.dart';  // ← حتماً این خط را در بالای فایل داشته باشید
import '../../../core/network/api_client.dart';
import 'note_models.dart';

class NoteRepository {
  final ApiClient _api;

  NoteRepository(this._api);

  // ============================================================
  // دریافت لیست یادداشت‌ها
  // ============================================================
  Future<NotesResponse> fetchNotes({
    int page = 1,
    int perPage = 10,
    String search = '',
    String? priority,
    String? color,
    bool? pinned,
    String? tag,
    String? due,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (priority != null && priority.isNotEmpty && priority != 'all')
          'priority': priority,
        if (color != null && color.isNotEmpty && color != 'all')
          'color': color,
        if (pinned != null) 'pinned': pinned ? '1' : '0',
        if (tag != null && tag.isNotEmpty) 'tag': tag.trim(),
        if (due != null && due.isNotEmpty) 'due': due,
      };

      final response = await _api.wpGet<Map<String, dynamic>>(
        '/wp-json/ei/v1/notes',
        queryParameters: params,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return NotesResponse.fromJson(data);
      }

      throw Exception('پاسخ نامعتبر از API یادداشت‌ها');
    } catch (e) {
      throw Exception('خطا در دریافت یادداشت‌ها: $e');
    }
  }

  // ============================================================
  // دریافت یک یادداشت
  // ============================================================
  Future<NoteItem> fetchNote(int id) async {
    try {
      final response = await _api.wpGet<dynamic>(
        '/wp-json/ei/v1/notes/$id',
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return NoteItem.fromJson(data);
      }

      throw Exception('پاسخ نامعتبر برای جزئیات یادداشت');
    } catch (e) {
      throw Exception('خطا در دریافت جزئیات یادداشت: $e');
    }
  }

  // ============================================================
  // ایجاد یادداشت جدید
  // ============================================================
  Future<NoteItem> createNote(NoteItem note) async {
    try {
      final response = await _api.wpPost<dynamic>(
        '/wp-json/ei/v1/notes',
        data: note.toJson(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return NoteItem.fromJson(data);
      }

      throw Exception('ایجاد یادداشت ناموفق بود');
    } catch (e) {
      throw Exception('خطا در ایجاد یادداشت: $e');
    }
  }

  // ============================================================
  // ویرایش یادداشت
  // ============================================================
  Future<NoteItem> updateNote(NoteItem note) async {
    if (note.id <= 0) {
      throw Exception('شناسه یادداشت نامعتبر است');
    }

    try {
      final response = await _api.wpPut<dynamic>(
        '/wp-json/ei/v1/notes/${note.id}',
        data: note.toJson(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return NoteItem.fromJson(data);
      }

      throw Exception('ویرایش یادداشت ناموفق بود');
    } catch (e) {
      throw Exception('خطا در ویرایش یادداشت: $e');
    }
  }

  // ============================================================
  // حذف یادداشت
  // ============================================================
  Future<void> deleteNote(int id) async {
    try {
      await _api.wpDelete<dynamic>(
        '/wp-json/ei/v1/notes/$id',
      );
    } catch (e) {
      throw Exception('خطا در حذف یادداشت: $e');
    }
  }

  // ============================================================
  // آپلود فایل پیوست (نسخه ساده‌شده بدون MediaType)
  // ============================================================
  Future<NoteFile> uploadFile({
    required String filePath,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      // استفاده از MultipartFile.fromFile به‌جای fromBytes
      // این متد خودش نوع فایل را از روی پسوند تشخیص می‌دهد
      final multipartFile = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      final response = await _api.uploadMedia<Map<String, dynamic>>(
        '/wp-json/ei/v1/notes/upload',
        formData: formData,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return NoteFile.fromJson(data);
      }

      throw Exception('آپلود فایل ناموفق بود');
    } catch (e) {
      throw Exception('خطا در آپلود فایل: $e');
    }
  }

  // ============================================================
  // دریافت قالب‌های آماده
  // ============================================================
  Future<List<NoteTemplate>> fetchTemplates() async {
    try {
      final response = await _api.wpGet<List<dynamic>>(
        '/wp-json/ei/v1/notes/templates',
      );

      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((e) => NoteTemplate.fromJson(e))
            .toList();
      }

      return const [];
    } catch (e) {
      return const [];
    }
  }

  // ============================================================
  // افزودن پاسخ (کامنت)
  // ============================================================
  Future<NoteReply> addReply({
    required int noteId,
    required String content,
    String? parentId,
  }) async {
    try {
      final response = await _api.wpPost<dynamic>(
        '/wp-json/ei/v1/notes/$noteId/replies',
        data: {
          'content': content,
          if (parentId != null) 'parent_id': parentId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('reply')) {
        final replyData = data['reply'] as Map<String, dynamic>;
        return NoteReply.fromJson(replyData);
      }

      throw Exception('افزودن پاسخ ناموفق بود');
    } catch (e) {
      throw Exception('خطا در افزودن پاسخ: $e');
    }
  }

  // ============================================================
  // حذف پاسخ
  // ============================================================
  Future<void> deleteReply({
    required int noteId,
    required String replyId,
  }) async {
    try {
      await _api.wpDelete<dynamic>(
        '/wp-json/ei/v1/notes/$noteId/replies/$replyId',
      );
    } catch (e) {
      throw Exception('خطا در حذف پاسخ: $e');
    }
  }
}