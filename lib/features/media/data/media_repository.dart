// lib/features/media/data/media_repository.dart

import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'media_models.dart';

class MediaRepository {
  final ApiClient _api;

  MediaRepository(this._api);

  Future<List<MediaItem>> fetchMedia({
    int page = 1,
    int perPage = 24,
    String? search,
    String? mediaType,
  }) async {
    final params = {
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (mediaType != null && mediaType.isNotEmpty) 'media_type': mediaType,
    };

    final response = await _api.get(
      '/wp-json/wp/v2/media',
      queryParameters: params,
    );

    return (response.data as List).map((e) => MediaItem.fromJson(e)).toList();
  }

  Future<MediaItem> fetchMediaItem(int id) async {
    final response = await _api.get('/wp-json/wp/v2/media/$id');
    return MediaItem.fromJson(response.data);
  }

  // ===== آپلود با استفاده از bytes (سازگار با وب) =====
  Future<MediaUploadResponse> uploadMediaFromBytes({
    required Uint8List bytes,
    required String fileName,
    String? title,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      ),
      if (title != null && title.isNotEmpty) 'title': title,
    });

    final response = await _api.uploadMedia<Map<String, dynamic>>(
      '/wp-json/wp/v2/media',
      formData: formData,
    );

    return MediaUploadResponse.fromJson(response.data!);
  }

  // ===== آپلود با فایل (برای پلتفرم‌های غیروب) =====
  Future<MediaUploadResponse> uploadMedia({
    required String filePath,
    required String fileName,
    String? title,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      if (title != null && title.isNotEmpty) 'title': title,
    });

    final response = await _api.uploadMedia<Map<String, dynamic>>(
      '/wp-json/wp/v2/media',
      formData: formData,
    );

    return MediaUploadResponse.fromJson(response.data!);
  }

  Future<MediaItem> updateMediaItem({
    required int id,
    String? title,
    String? altText,
  }) async {
    final data = {
      if (title != null) 'title': title,
      if (altText != null) 'alt_text': altText,
    };
    final response = await _api.post(
      '/wp-json/wp/v2/media/$id',
      data: data,
    );
    return MediaItem.fromJson(response.data);
  }

  // حذف رسانه از WordPress REST API با همان لایه احراز هویت WordPress/Manager.
  // این endpoint متعلق به WooCommerce نیست و نباید با consumer key/secret صدا زده شود.
  Future<void> deleteMediaItem(int id) async {
    await _api.wpDelete(
      '/wp-json/wp/v2/media/$id',
      queryParameters: {'force': true},
    );
  }

  Future<int> fetchTotalCount({
    String? search,
    String? mediaType,
  }) async {
    final params = {
      'per_page': 1,
      if (search != null && search.isNotEmpty) 'search': search,
      if (mediaType != null && mediaType.isNotEmpty) 'media_type': mediaType,
    };
    final response = await _api.get(
      '/wp-json/wp/v2/media',
      queryParameters: params,
    );
    final total = response.headers['x-wp-total']?.first;
    return int.tryParse(total ?? '0') ?? 0;
  }
}