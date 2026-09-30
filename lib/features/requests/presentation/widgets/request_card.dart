import 'package:flutter/material.dart';
import '../../data/request_models.dart';
import 'request_status_badge.dart';

class RequestCard extends StatelessWidget {
  final RequestItem item;
  final VoidCallback onTap;
  final VoidCallback onProcess;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const RequestCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onProcess,
    required this.onReject,
    required this.onDelete,
  });

  String _date(String? value) {
    if (value == null || value.isEmpty) {
      return '—';
    }

    final d = DateTime.tryParse(value);

    if (d == null) {
      return value;
    }

    final local = d.toLocal();

    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _infoLine({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 7),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  RequestStatusBadge(
                    status: item.status,
                  ),
                  const Spacer(),
                  Text(
                    '#${item.id}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Name
              Text(
                item.name?.trim().isNotEmpty == true
                    ? item.name!
                    : 'بدون نام',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),

              if (item.subject?.trim().isNotEmpty ==
                  true) ...[
                const SizedBox(height: 4),
                Text(
                  item.subject!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 13),

              // Form
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _infoLine(
                      icon: Icons.description_outlined,
                      label: 'فرم',
                      value: item.displayFormTitle,
                    ),
                    _infoLine(
                      icon: Icons.web_outlined,
                      label: 'صفحه',
                      value: item.displaySourcePage,
                    ),
                    _infoLine(
                      icon: Icons.schedule_outlined,
                      label: 'تاریخ',
                      value: _date(
                        item.date ??
                            item.createdAt,
                      ),
                    ),
                  ],
                ),
              ),

              if (item.phone?.trim().isNotEmpty ==
                  true) ...[
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      item.phone!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],

              if (item.message?.trim().isNotEmpty ==
                  true) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.message!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 11),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(
                        Icons.visibility_outlined,
                        size: 17,
                      ),
                      label: const Text(
                        'مشاهده',
                      ),
                    ),
                  ),

                  if (item.status !=
                      'processed') ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child:
                          OutlinedButton.icon(
                        onPressed: onProcess,
                        icon: const Icon(
                          Icons.check_circle_outline,
                          size: 17,
                        ),
                        label: const Text(
                          'بررسی شد',
                        ),
                      ),
                    ),
                  ],

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'reject') {
                        onReject();
                      }

                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'reject',
                        child: Text(
                          'رد کردن',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'حذف درخواست',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}