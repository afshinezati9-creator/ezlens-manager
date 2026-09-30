import 'dart:html' as web;

/// Opens a new tab with the rendered HTML+CSS+JS preview.
/// Only available on Flutter Web.
Future<bool> openCodePreview(String htmlCode, String cssCode, String jsCode) async {
  final fullHtml = '''
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>پیش‌نمایش کد</title>
  <link href="https://fonts.googleapis.com/css2?family=Vazirmatn:wght@300;400;600;700;800&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: 'Vazirmatn', Tahoma, Arial, sans-serif;
      padding: 20px;
      margin: 0;
      background: #ffffff;
      color: #1a1a1a;
      line-height: 1.8;
      direction: rtl;
      text-align: right;
    }
    $cssCode
  </style>
</head>
<body>
$htmlCode
<script>
try {
  $jsCode
} catch (e) {
  console.error('Preview JS error:', e);
}
</script>
</body>
</html>
''';

  final blob = web.Blob([fullHtml], 'text/html;charset=utf-8');
  final url = web.Url.createObjectUrlFromBlob(blob);
  web.window.open(url, '_blank');

  // Release after 60 seconds
  Future.delayed(const Duration(seconds: 60), () {
    try {
      web.Url.revokeObjectUrl(url);
    } catch (_) {}
  });

  return true;
}