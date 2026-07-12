import 'package:flutter/material.dart';
import '../core/helpers/format_helper.dart';
import '../models/maintenance_model.dart';

class MaintenanceCard extends StatelessWidget {
  final MaintenanceRequestModel item;
  final VoidCallback? onTap;

  const MaintenanceCard({super.key, required this.item, this.onTap});

  String get statusText {
    switch (item.status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return item.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phòng: ${item.roomNumber ?? item.roomId ?? ''}'),
              Text('Người thuê: ${item.tenantName ?? ''}'),
              Text('Ngày gửi: ${FormatHelper.dateTime(item.createdAt)}'),
            ],
          ),
        ),
        trailing: Text(statusText),
      ),
    );
  }
}
