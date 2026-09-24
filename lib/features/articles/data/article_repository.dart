// lib/features/articles/data/article_repository.dart

import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import 'article_models.dart';

class ArticleRepository {
  final ApiClient _api;

  ArticleRepository(this._api);

  /// Build WP content that keeps CSS/JS for front-end AND editor reload.
  static String buildPersistContentLoose(String html, String css, String js) {
    final buf = StringBuffer();
    buf.write(html.trim());
    final c = css.trim();
    final j = js.trim();
    if (c.isNotEmpty) {
      buf.write('\n<style type="text/css" id="ezlens-article-css">\n');
      buf.write(c);
      buf.write('\n</style>');
    }
    if (j.isNotEmpty) {
      buf.write('\n<script type="text/javascript" id="ezlens-article-js">\n');
      buf.write(j.replaceAll('</script>', r'<\/script>'));
      buf.write('\n</script>');
    }
    if (c.isNotEmpty || j.isNotEmpty) {
      buf.write('\n<!--EZLENS_CODE\n');
      buf.write('/**CSS**/\n');
      buf.write(c);
      buf.write('\n/**JS**/\n');
      buf.write(j);
      buf.write('\nEZLENS_CODE-->');
    }
    return buf.toString();
  }

  static String buildPersistContent(String html, String css, String js) {
    final probe = html.trim();
    final isFullDoc = probe.contains('<!DOCTYPE') ||
        RegExp(r'<html[\s>]', caseSensitive: false).hasMatch(probe) ||
        RegExp(r'<body[\s>]', caseSensitive: false).hasMatch(probe);
    final loose = buildPersistContentLoose(html, css, js);
    if (isFullDoc) {
      return sanitizeHtmlForWp(loose);
    }
    return sanitizeHtmlForWp(loose);
  }

  /// Strip full-document wrappers so WP theme + wpautop do not break CSS/JS.
  static String sanitizeHtmlForWp(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;

    final styles = <String>[];
    final scripts = <String>[];
    final jsonLd = <String>[];

    final styleRe = RegExp(r'<style[^>]*>([\s\S]*?)</style>', caseSensitive: false);
    for (final m in styleRe.allMatches(s)) {
      final body = (m.group(1) ?? '').trim();
      if (body.isNotEmpty) styles.add(body);
    }

    final jsonLdRe = RegExp(
      r"""<script[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>([\s\S]*?)</script>""",
      caseSensitive: false,
    );
    for (final m in jsonLdRe.allMatches(s)) {
      jsonLd.add(m.group(0)!);
    }

    final scriptRe = RegExp(
      r'<script(?![^>]*application/ld\+json)[^>]*>([\s\S]*?)</script>',
      caseSensitive: false,
    );
    for (final m in scriptRe.allMatches(s)) {
      final body = (m.group(1) ?? '').trim();
      if (body.isNotEmpty) scripts.add(body);
    }

    String html = s;
    final bodyM = RegExp(r'<body[^>]*>([\s\S]*?)</body>', caseSensitive: false).firstMatch(s);
    if (bodyM != null) {
      html = bodyM.group(1) ?? '';
    } else if (RegExp(r'<!DOCTYPE\s+html', caseSensitive: false).hasMatch(s) ||
        RegExp(r'<html[\s>]', caseSensitive: false).hasMatch(s)) {
      html = s.replaceAll(RegExp(r'<head[^>]*>[\s\S]*?</head>', caseSensitive: false), '');
      html = html.replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '');
      html = html.replaceAll(RegExp(r'</?html[^>]*>', caseSensitive: false), '');
      html = html.replaceAll(RegExp(r'</?body[^>]*>', caseSensitive: false), '');
    }

    html = html.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');
    html = html.replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '');
    html = html.replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '');
    html = html.replaceAll(RegExp(r'</?html[^>]*>', caseSensitive: false), '');
    html = html.replaceAll(RegExp(r'<head[^>]*>[\s\S]*?</head>', caseSensitive: false), '');
    html = html.trim();

    final buf = StringBuffer();
    if (html.isNotEmpty) buf.write(html);
    for (final j in jsonLd) {
      buf.write('\n');
      buf.write(j);
    }
    if (styles.isNotEmpty) {
      buf.write('\n<style type="text/css" id="ezlens-article-css">\n');
      buf.write(styles.join('\n\n'));
      buf.write('\n</style>');
    }
    if (scripts.isNotEmpty) {
      buf.write('\n<script type="text/javascript" id="ezlens-article-js">\n');
      final js = scripts.join('\n\n').replaceAll('</script>', r'<\/script>');
      buf.write(js);
      buf.write('\n</script>');
    }
    return buf.toString().trim();
  }


  /// Parse stored content back to [html, css, js].
  static List<String> parsePersistContent(String raw) {
    if (raw.trim().isEmpty) return ['', '', ''];

    // 1) Marker comment block (preferred round-trip)
    final marker = RegExp(
      r'<!--EZLENS_CODE\s*([\s\S]*?)EZLENS_CODE-->',
      caseSensitive: false,
    );
    final m = marker.firstMatch(raw);
    if (m != null) {
      final block = m.group(1) ?? '';
      String css = '';
      String js = '';
      final cssIdx = block.indexOf('/**CSS**/');
      final jsIdx = block.indexOf('/**JS**/');
      if (cssIdx != -1 && jsIdx != -1 && jsIdx > cssIdx) {
        css = block.substring(cssIdx + '/**CSS**/'.length, jsIdx).trim();
        js = block.substring(jsIdx + '/**JS**/'.length).trim();
      } else if (cssIdx != -1) {
        css = block.substring(cssIdx + '/**CSS**/'.length).trim();
      } else if (jsIdx != -1) {
        js = block.substring(jsIdx + '/**JS**/'.length).trim();
      }
      var html = raw.replaceFirst(marker, '').trim();
      html = _stripArticleStyleScript(html);
      return [html, css, js];
    }

    // 2) Live style/script tags by id (double or single quotes)
    final cssRe = RegExp(
      '<style[^>]*id\\s*=\\s*["\']ezlens-article-css["\'][^>]*>([\\s\\S]*?)</style>',
      caseSensitive: false,
    );
    final jsRe = RegExp(
      '<script[^>]*id\\s*=\\s*["\']ezlens-article-js["\'][^>]*>([\\s\\S]*?)</script>',
      caseSensitive: false,
    );
    final cssM = cssRe.firstMatch(raw);
    final jsM = jsRe.firstMatch(raw);
    if (cssM != null || jsM != null) {
      final css = cssM?.group(1)?.trim() ?? '';
      final js = jsM?.group(1)?.trim() ?? '';
      final html = _stripArticleStyleScript(raw);
      return [html, css, js];
    }

    // 3) Plain UnifiedCodeEditor markers in body
    const cssTag = '/**CSS**/';
    const jsTag = '/**JS**/';
    final cssIdx = raw.indexOf(cssTag);
    final jsIdx = raw.indexOf(jsTag);
    if (cssIdx != -1 || jsIdx != -1) {
      if (cssIdx != -1 && jsIdx != -1 && cssIdx < jsIdx) {
        return [
          raw.substring(0, cssIdx).trim(),
          raw.substring(cssIdx + cssTag.length, jsIdx).trim(),
          raw.substring(jsIdx + jsTag.length).trim(),
        ];
      }
      if (cssIdx != -1) {
        return [
          raw.substring(0, cssIdx).trim(),
          raw.substring(cssIdx + cssTag.length).trim(),
          '',
        ];
      }
      return [
        raw.substring(0, jsIdx).trim(),
        '',
        raw.substring(jsIdx + jsTag.length).trim(),
      ];
    }

    return [raw.trim(), '', ''];
  }

  static String _stripArticleStyleScript(String html) {
    var out = html;
    out = out.replaceAll(
      RegExp(
        '<style[^>]*id\\s*=\\s*["\']ezlens-article-css["\'][^>]*>[\\s\\S]*?</style>',
        caseSensitive: false,
      ),
      '',
    );
    out = out.replaceAll(
      RegExp(
        '<script[^>]*id\\s*=\\s*["\']ezlens-article-js["\'][^>]*>[\\s\\S]*?</script>',
        caseSensitive: false,
      ),
      '',
    );
    return out.trim();
  }

  Map<String, dynamic> _normalizePayload(Map<String, dynamic> data) {
    final out = Map<String, dynamic>.from(data);

    String html = (out['content'] ?? '').toString();
    String css = '';
    String js = '';
    final rankMeta = <String, dynamic>{};

    final metaList = out['meta_data'];
    if (metaList is List) {
      for (final e in metaList) {
        if (e is! Map) continue;
        final k = '${e['key'] ?? ''}';
        final v = e['value']?.toString() ?? '';
        if (k == 'ezlens_desc_css') css = v;
        if (k == 'ezlens_desc_js') js = v;
        if (k.startsWith('rank_math_')) rankMeta[k] = v;
      }
    }

    // If caller already passed full unified/persist content without meta css
    if (css.isEmpty && js.isEmpty) {
      final parsed = parsePersistContent(html);
      if (parsed[1].isNotEmpty || parsed[2].isNotEmpty) {
        html = parsed[0];
        css = parsed[1];
        js = parsed[2];
      }
    }

    out['content'] = sanitizeHtmlForWp(buildPersistContent(html, css, js));
    if (rankMeta.isNotEmpty) {
      out['meta'] = rankMeta;
    }
    out.remove('meta_data');
    return out;
  }

  Future<List<Article>> fetchArticles({
    int page = 1,
    int perPage = 10,
    String? search,
    int? categoryId,
    int? tagId,
    String? status,
    String? sort,
    String? dateFrom,
    String? dateTo,
  }) async {
    final params = {
      'page': page,
      'per_page': perPage,
      '_embed': 'true',
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'categories': categoryId,
      if (tagId != null) 'tags': tagId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (sort == 'newest') ...{'orderby': 'date', 'order': 'desc'},
      if (sort == 'oldest') ...{'orderby': 'date', 'order': 'asc'},
      if (sort == 'views')
        ...{
          'orderby': 'meta_value_num',
          'meta_key': 'views',
          'order': 'desc'
        },
      if (sort == 'title') ...{'orderby': 'title', 'order': 'asc'},
      if (dateFrom != null && dateFrom.isNotEmpty) 'after': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'before': dateTo,
    };

    final response = await _api.wpGet<List<dynamic>>(
      '/wp-json/wp/v2/posts',
      queryParameters: params,
    );
    return (response.data ?? [])
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> fetchTotalArticles({
    String? search,
    int? categoryId,
    int? tagId,
    String? status,
    String? sort,
    String? dateFrom,
    String? dateTo,
  }) async {
    final params = {
      'per_page': 1,
      'page': 1,
      '_embed': 'false',
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'categories': categoryId,
      if (tagId != null) 'tags': tagId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (sort == 'newest') ...{'orderby': 'date', 'order': 'desc'},
      if (sort == 'oldest') ...{'orderby': 'date', 'order': 'asc'},
      if (sort == 'views')
        ...{
          'orderby': 'meta_value_num',
          'meta_key': 'views',
          'order': 'desc'
        },
      if (sort == 'title') ...{'orderby': 'title', 'order': 'asc'},
      if (dateFrom != null && dateFrom.isNotEmpty) 'after': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'before': dateTo,
    };

    final response = await _api.wpGet<List<dynamic>>(
      '/wp-json/wp/v2/posts',
      queryParameters: params,
    );
    final totalHeader = response.headers['x-wp-total']?.first;
    return int.tryParse(totalHeader ?? '0') ?? 0;
  }

  Future<Article> fetchArticle(int id) async {
    final response = await _api.wpGet<Map<String, dynamic>>(
      '/wp-json/wp/v2/posts/$id',
      queryParameters: {
        '_embed': 'true',
        'context': 'edit',
      },
    );
    return Article.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Article> createArticle(Map<String, dynamic> data) async {
    final payload = _normalizePayload(data);
    final c = (payload['content'] ?? '').toString();
    if (kDebugMode) {
      debugPrint('📝 CREATE ARTICLE — content len: ${c.length}');
    }
    final response = await _api.wpPost<Map<String, dynamic>>(
      '/wp-json/wp/v2/posts',
      data: payload,
      queryParameters: {'context': 'edit'},
    );
    final created = Article.fromJson(response.data as Map<String, dynamic>);
    if (c.trim().isEmpty) return created;

    // Ensure Elementor does not take over a newly created HTML article
    try {
      await _api.wpPost<Map<String, dynamic>>(
        '/wp-json/ezlens/v1/manager/posts/${created.id}/apply-content',
        data: {
          'content': sanitizeHtmlForWp(c),
          'disable_elementor': true,
          if (payload['title'] != null) 'title': payload['title'],
          if (payload['status'] != null) 'status': payload['status'],
        },
      );
    } catch (_) {}
    return fetchArticle(created.id);
  }

  Future<Article> updateArticle(int id, Map<String, dynamic> data) async {
    final payload = _normalizePayload(data);
    final c = (payload['content'] ?? '').toString().trim();
    if (c.isEmpty) {
      payload.remove('content');
      if (kDebugMode) {
        debugPrint('📝 UPDATE ARTICLE #$id — content OMITTED (empty, keep existing)');
      }
      final response = await _api.wpPut<Map<String, dynamic>>(
        '/wp-json/wp/v2/posts/$id',
        data: payload,
        queryParameters: {'context': 'edit'},
      );
      return Article.fromJson(response.data as Map<String, dynamic>);
    }

    if (kDebugMode) {
      debugPrint('📝 UPDATE ARTICLE #$id — force-apply content len: ${c.length}');
    }

    // 1) Standard WP fields without content
    final metaOnly = Map<String, dynamic>.from(payload)..remove('content');
    try {
      await _api.wpPut<Map<String, dynamic>>(
        '/wp-json/wp/v2/posts/$id',
        data: metaOnly,
        queryParameters: {'context': 'edit'},
      );
    } catch (_) {}

    final rank = <String, dynamic>{};
    if (payload['meta'] is Map) {
      rank.addAll(Map<String, dynamic>.from(payload['meta'] as Map));
    }

    // 2) Prefer manager force-apply (clears Elementor)
    try {
      final applied = await _api.wpPost<Map<String, dynamic>>(
        '/wp-json/ezlens/v1/manager/posts/$id/apply-content',
        data: {
          'content': sanitizeHtmlForWp(c),
          'disable_elementor': true,
          if (payload['title'] != null) 'title': payload['title'],
          if (payload['excerpt'] != null) 'excerpt': payload['excerpt'],
          if (payload['status'] != null) 'status': payload['status'],
          if (payload['slug'] != null) 'slug': payload['slug'],
          if (payload['categories'] is List) 'categories': payload['categories'],
          if (rank.isNotEmpty) 'meta': rank,
        },
      );
      if (kDebugMode) {
        debugPrint('✅ FORCE APPLY — ${applied.data}');
      }
      if (applied.data?['ok'] == true) {
        return fetchArticle(id);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ apply-content failed, fallback WP content: $e');
      }
    }

    // 3) Fallback: classic content + try clear Elementor via registered meta
    final fallback = Map<String, dynamic>.from(payload);
    fallback['content'] = c;
    final meta = <String, dynamic>{
      if (rank.isNotEmpty) ...rank,
      '_elementor_edit_mode': '',
      '_elementor_data': '',
      '_elementor_template_type': '',
    };
    fallback['meta'] = meta;
    final response = await _api.wpPut<Map<String, dynamic>>(
      '/wp-json/wp/v2/posts/$id',
      data: fallback,
      queryParameters: {'context': 'edit'},
    );
    return Article.fromJson(response.data as Map<String, dynamic>);
  }


  Future<void> deleteArticle(int id) async {
    await _api.wpDelete(
      '/wp-json/wp/v2/posts/$id',
      queryParameters: {'force': 'true'},
    );
  }

  Future<List<ArticleCategory>> fetchCategories() async {
    List<ArticleCategory> allCategories = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      try {
        final response = await _api.wpGet<List<dynamic>>(
          '/wp-json/wp/v2/categories',
          queryParameters: {
            'per_page': 100,
            'page': page,
            'hide_empty': 'false',
          },
        );
        final data = response.data ?? [];
        if (data.isEmpty) {
          hasMore = false;
        } else {
          allCategories.addAll(
            data.map(
              (e) => ArticleCategory.fromJson(e as Map<String, dynamic>),
            ),
          );
          if (data.length < 100) {
            hasMore = false;
          } else {
            page++;
          }
        }
      } catch (e) {
        if (allCategories.isEmpty) rethrow;
        break;
      }
    }
    return allCategories;
  }

  Future<ArticleCategory> createCategory(Map<String, dynamic> data) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '/wp-json/wp/v2/categories',
      data: data,
    );
    return ArticleCategory.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) async {
    await _api.wpDelete(
      '/wp-json/wp/v2/categories/$id',
      queryParameters: {'force': 'true'},
    );
  }

  Future<List<ArticleTag>> fetchTags() async {
    List<ArticleTag> allTags = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      try {
        final response = await _api.wpGet<List<dynamic>>(
          '/wp-json/wp/v2/tags',
          queryParameters: {
            'per_page': 100,
            'page': page,
            'hide_empty': 'false',
          },
        );
        final data = response.data ?? [];
        if (data.isEmpty) {
          hasMore = false;
        } else {
          allTags.addAll(
            data.map(
              (e) => ArticleTag.fromJson(e as Map<String, dynamic>),
            ),
          );
          if (data.length < 100) {
            hasMore = false;
          } else {
            page++;
          }
        }
      } catch (e) {
        if (allTags.isEmpty) rethrow;
        break;
      }
    }
    return allTags;
  }

  Future<ArticleTag> createTag(Map<String, dynamic> data) async {
    final response = await _api.wpPost<Map<String, dynamic>>(
      '/wp-json/wp/v2/tags',
      data: data,
    );
    return ArticleTag.fromJson(response.data as Map<String, dynamic>);
  }
}
