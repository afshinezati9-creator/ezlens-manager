library;

class PurchaseScript {
  final int id;
  final String title;
  final String filename;
  final String description;
  final bool active;
  final String createdFa;
  final String updatedFa;
  final String code;
  final bool fileExists;

  const PurchaseScript({
    required this.id,
    this.title = '',
    this.filename = '',
    this.description = '',
    this.active = false,
    this.createdFa = '',
    this.updatedFa = '',
    this.code = '',
    this.fileExists = true,
  });

  factory PurchaseScript.fromJson(Map<String, dynamic> json) {
    return PurchaseScript(
      id: int.tryParse('${json['id']}') ?? 0,
      title: (json['title'] ?? '').toString(),
      filename: (json['filename'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      active: json['active'] == true ||
          json['status'] == 1 ||
          json['status'] == '1',
      createdFa: (json['created_fa'] ?? json['created_at'] ?? '').toString(),
      updatedFa: (json['updated_fa'] ?? json['updated_at'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      fileExists: json['file_exists'] != false,
    );
  }
}
