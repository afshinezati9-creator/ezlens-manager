import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ===== import شرطی برای پیش‌نمایش (فقط روی Web کار می‌کند) =====
import 'code_preview_stub.dart'
    if (dart.library.html) 'code_preview_web.dart';

/// ویرایشگر کد یکپارچه HTML + CSS + JS
/// - نوشتن از چپ به راست (LTR)
/// - شماره خطوط در سمت چپ
/// - دکمه‌های کپی، حذف، تست
/// - پس‌زمینه تیره و فونت روشن
class UnifiedCodeEditor extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final double minHeight;
  final String? hint;
  /// When provided, parent owns the text — always use this on save.
  final TextEditingController? controller;

  const UnifiedCodeEditor({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.minHeight = 360,
    this.hint,
    this.controller,
  });

  /// ساخت کد یکپارچه از بخش‌های جدا
  static String combine(String html, String css, String js) {
    final h = html.trim();
    final c = css.trim();
    final j = js.trim();

    if (h.isEmpty && c.isEmpty && j.isEmpty) return '';

    final buf = StringBuffer();
    buf.write(h);
    buf.write('\n\n/**CSS**/\n');
    buf.write(c);
    buf.write('\n\n/**JS**/\n');
    buf.write(j);
    return buf.toString();
  }

  /// تقسیم کد یکپارچه به بخش‌ها → [html, css, js]
  static List<String> split(String code) {
    if (code.trim().isEmpty) return ['', '', ''];

    const cssTag = '/**CSS**/';
    const jsTag = '/**JS**/';

    final cssIdx = code.indexOf(cssTag);
    final jsIdx = code.indexOf(jsTag);

    if (cssIdx == -1 && jsIdx == -1) {
      return [code.trim(), '', ''];
    }
    if (cssIdx != -1 && jsIdx == -1) {
      return [
        code.substring(0, cssIdx).trim(),
        code.substring(cssIdx + cssTag.length).trim(),
        '',
      ];
    }
    if (cssIdx == -1 && jsIdx != -1) {
      return [
        code.substring(0, jsIdx).trim(),
        '',
        code.substring(jsIdx + jsTag.length).trim(),
      ];
    }
    if (cssIdx < jsIdx) {
      return [
        code.substring(0, cssIdx).trim(),
        code.substring(cssIdx + cssTag.length, jsIdx).trim(),
        code.substring(jsIdx + jsTag.length).trim(),
      ];
    }
    return [
      code.substring(0, jsIdx).trim(),
      code.substring(cssIdx + cssTag.length).trim(),
      code.substring(jsIdx + jsTag.length, cssIdx).trim(),
    ];
  }

  @override
  State<UnifiedCodeEditor> createState() => _UnifiedCodeEditorState();
}

class _UnifiedCodeEditorState extends State<UnifiedCodeEditor> {
  late TextEditingController _controller;
  bool _ownsController = false;
  late final ScrollController _textScroll;
  late final ScrollController _linesScroll;

  int _lineCount = 1;
  int _charCount = 0;
  _EditorSection _currentSection = _EditorSection.html;
  bool _isPreviewing = false;

  // ارتفاع هر خط = fontSize * height = 13 * 1.45 = 18.85
  static const double _lineHeight = 18.85;
  static const double _padTop = 14;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
      if (_controller.text.isEmpty && widget.initialValue.isNotEmpty) {
        _controller.text = widget.initialValue;
      }
    } else {
      _controller = TextEditingController(text: widget.initialValue);
      _ownsController = true;
    }
    _textScroll = ScrollController();
    _linesScroll = ScrollController();

    _recalcCounts();
    _updateSection();

    _textScroll.addListener(_syncLineScroll);
    _controller.addListener(_onTextChanged);
  }

  void _syncLineScroll() {
    if (_textScroll.hasClients && _linesScroll.hasClients) {
      final offset = _textScroll.offset;
      if ((_linesScroll.offset - offset).abs() > 0.5) {
        _linesScroll.jumpTo(
          offset.clamp(0.0, _linesScroll.position.maxScrollExtent),
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant UnifiedCodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // External controller is source of truth — do not clobber user typing
    if (widget.controller != null) {
      if (oldWidget.controller != widget.controller) {
        if (_ownsController) {
          _controller.removeListener(_onTextChanged);
          _controller.dispose();
        }
        _controller = widget.controller!;
        _ownsController = false;
        _controller.removeListener(_onTextChanged);
        _controller.addListener(_onTextChanged);
        _recalcCounts();
        _updateSection();
      }
      return;
    }
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
      _recalcCounts();
      _updateSection();
    }
  }

  void _onTextChanged() {
    _recalcCounts();
    _updateSection();
    widget.onChanged(_controller.text);
    setState(() {});
  }

  void _recalcCounts() {
    final t = _controller.text;
    _lineCount = '\n'.allMatches(t).length + 1;
    _charCount = t.length;
  }

  void _updateSection() {
    final sel = _controller.selection;
    if (!sel.isValid) {
      _currentSection = _EditorSection.html;
      return;
    }
    final pos = sel.baseOffset;
    final text = _controller.text;

    final cssIdx = text.indexOf('/**CSS**/');
    final jsIdx = text.indexOf('/**JS**/');

    if (cssIdx != -1 && jsIdx != -1 && cssIdx < jsIdx) {
      if (pos >= jsIdx) {
        _currentSection = _EditorSection.js;
      } else if (pos >= cssIdx) {
        _currentSection = _EditorSection.css;
      } else {
        _currentSection = _EditorSection.html;
      }
    } else if (cssIdx != -1 && (jsIdx == -1 || pos < cssIdx)) {
      _currentSection =
          pos < cssIdx ? _EditorSection.html : _EditorSection.css;
    } else if (jsIdx != -1 && (cssIdx == -1 || pos < jsIdx)) {
      _currentSection =
          pos < jsIdx ? _EditorSection.html : _EditorSection.js;
    } else {
      _currentSection = _EditorSection.html;
    }
  }

  @override
  void dispose() {
    _textScroll.removeListener(_syncLineScroll);
    _controller.removeListener(_onTextChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    _textScroll.dispose();
    _linesScroll.dispose();
    super.dispose();
  }

  void _insertAtCursor(String text) {
    final sel = _controller.selection;
    final current = _controller.text;
    final start = sel.isValid ? sel.start : current.length;
    final end = sel.isValid ? sel.end : current.length;

    final newText = current.replaceRange(start, end, text);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
  }

  void _jumpToSection(_EditorSection section) {
    final text = _controller.text;
    int offset = 0;

    if (section == _EditorSection.html) {
      offset = 0;
    } else if (section == _EditorSection.css) {
      final idx = text.indexOf('/**CSS**/');
      offset = idx == -1 ? 0 : idx + '/**CSS**/'.length + 1;
    } else if (section == _EditorSection.js) {
      final idx = text.indexOf('/**JS**/');
      offset = idx == -1 ? 0 : idx + '/**JS**/'.length + 1;
    }

    _controller.selection = TextSelection.collapsed(offset: offset);
    _updateSection();
    setState(() {});
  }

  // ===== کپی به کلیپ‌بورد =====
  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('کد کپی شد'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }

  // ===== حذف کامل با تأیید =====
  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('پاک کردن کد'),
          ],
        ),
        content: const Text(
          'کل محتوای ویرایشگر پاک شود؟\nاین عمل قابل بازگشت نیست.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('پاک کن'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    _controller.text = '';
    _recalcCounts();
    setState(() {});
  }

  // ===== تست کد (پیش‌نمایش) =====
  Future<void> _previewCode() async {
    setState(() => _isPreviewing = true);

    final parts = UnifiedCodeEditor.split(_controller.text);
    final htmlCode = parts[0];
    final cssCode = parts[1];
    final jsCode = parts[2];

    try {
      final ok = await openCodePreview(htmlCode, cssCode, jsCode);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('پیش‌نمایش فقط روی وب در دسترس است'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در پیش‌نمایش: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPreviewing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = List.generate(_lineCount, (i) => i + 1);

    // Theme اختصاصی برای جلوگیری از پس‌زمینه سفید در TextField
    final editorTheme = Theme.of(context).copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF60A5FA),
        selectionColor: Color(0x5560A5FA),
        selectionHandleColor: Color(0xFF60A5FA),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================================================
              // نوار بالا: عنوان، بخش فعال، تعداد خط و کاراکتر
              // ==================================================
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: const Color(0xFF1E293B),
                child: Row(
                  children: [
                    const Icon(Icons.code,
                        size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    const Text(
                      'HTML  ·  CSS  ·  JS',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _currentSection.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _currentSection.color.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        _currentSection.label,
                        style: TextStyle(
                          color: _currentSection.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$_lineCount خط · $_charCount کاراکتر',
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // Toolbar: HTML / CSS / JS + actions
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: const Color(0xFF131C2E),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _smallBtn(
                      icon: Icons.html,
                      label: 'HTML',
                      color: const Color(0xFFE34C26),
                      onTap: () => _jumpToSection(_EditorSection.html),
                    ),
                    _smallBtn(
                      icon: Icons.css,
                      label: 'CSS',
                      color: const Color(0xFF2965F1),
                      onTap: () {
                        if (!_controller.text.contains('/**CSS**/')) {
                          _insertAtCursor('\n\n/**CSS**/\n/* styles */\n');
                        } else {
                          _jumpToSection(_EditorSection.css);
                        }
                      },
                    ),
                    _smallBtn(
                      icon: Icons.javascript,
                      label: 'JS',
                      color: const Color(0xFFF7DF1E),
                      onTap: () {
                        if (!_controller.text.contains('/**JS**/')) {
                          _insertAtCursor('\n\n/**JS**/\n// scripts\n');
                        } else {
                          _jumpToSection(_EditorSection.js);
                        }
                      },
                    ),
                    _actionBtn(
                      icon: Icons.copy,
                      label: 'کپی',
                      color: const Color(0xFF60A5FA),
                      onTap: _copyAll,
                    ),
                    _actionBtn(
                      icon: Icons.delete_outline,
                      label: 'پاک',
                      color: const Color(0xFFF87171),
                      onTap: _clearAll,
                    ),
                    _actionBtn(
                      icon: Icons.play_arrow_rounded,
                      label: _isPreviewing ? '...' : 'تست',
                      color: const Color(0xFF10B981),
                      onTap: _isPreviewing ? null : _previewCode,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // بدنه اصلی: خط‌شمار (چپ) + متن (راست)
              // ==================================================
              SizedBox(
                height: widget.minHeight,
                child: Container(
                  color: const Color(0xFF0F172A),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ===== خط‌شمار (سمت چپ) =====
                        Container(
                          width: 50,
                          color: const Color(0xFF0B1424),
                          child: SingleChildScrollView(
                            controller: _linesScroll,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: _padTop, bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: lines
                                    .map(
                                      (n) => SizedBox(
                                        height: _lineHeight,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 10),
                                          child: Align(
                                            alignment:
                                                Alignment.centerRight,
                                            child: Text(
                                              '$n',
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 13,
                                                height: 1.45,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ),

                        // ===== جداکننده عمودی =====
                        Container(
                          width: 1,
                          color: const Color(0xFF1E293B),
                        ),

                        // ===== متن اصلی =====
                        Expanded(
                          child: Container(
                            color: const Color(0xFF0F172A),
                            child: Theme(
                              data: editorTheme,
                              child: TextField(
                                controller: _controller,
                                scrollController: _textScroll,
                                maxLines: null,
                                expands: true,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  height: 1.45,
                                  color: Color(0xFFF1F5F9),
                                  letterSpacing: 0.3,
                                ),
                                cursorColor: const Color(0xFF60A5FA),
                                cursorWidth: 2,
                                textAlignVertical: TextAlignVertical.top,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.only(
                                    left: 12,
                                    right: 12,
                                    top: _padTop,
                                    bottom: 14,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  hintText: widget.hint ??
                                      '<!-- HTML -->\n\n/**CSS**/\n/* styles */\n\n/**JS**/\n// scripts',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== دکمه کوچک برای HTML/CSS/JS =====
  Widget _smallBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== دکمه اکشن (کپی/حذف/تست) =====
  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _EditorSection {
  html('HTML', Color(0xFFE34C26)),
  css('CSS', Color(0xFF2965F1)),
  js('JS', Color(0xFFF7DF1E));

  final String label;
  final Color color;
  const _EditorSection(this.label, this.color);
}