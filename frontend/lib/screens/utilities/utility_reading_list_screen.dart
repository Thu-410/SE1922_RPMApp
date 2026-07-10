import 'package:flutter/material.dart';
import '../../core/helpers/formatters.dart';
import '../../core/network/api_client.dart';
import '../../models/service_price.dart';
import '../../models/utility_reading.dart';
import '../../services/utility_service.dart';
import '../../widgets/error_view.dart';
import 'service_price_screen.dart';
import 'utility_reading_form_screen.dart';

class UtilityReadingListScreen extends StatefulWidget {
  const UtilityReadingListScreen({super.key, required this.apiClient, this.isManager = false});
  final ApiClient apiClient;
  final bool isManager;

  @override
  State<UtilityReadingListScreen> createState() => _UtilityReadingListScreenState();
}

class _UtilityReadingListScreenState extends State<UtilityReadingListScreen> {
  late final UtilityService _service;
  late Future<(ServicePrice, List<UtilityReading>)> _future;

  @override
  void initState() {
    super.initState();
    _service = UtilityService(widget.apiClient);
    _load();
  }

  void _load() => _future = Future.wait([_service.getCurrentPrice(), _service.getReadings()])
      .then((values) => (values[0] as ServicePrice, values[1] as List<UtilityReading>));

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  Future<void> _openReadingForm([UtilityReading? reading]) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => UtilityReadingFormScreen(apiClient: widget.apiClient, reading: reading)));
    if (changed == true) setState(_load);
  }

  Future<void> _delete(UtilityReading reading) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Xóa chỉ số?'),
      content: Text('${reading.roomNumber} tháng ${reading.month}/${reading.year}'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa'))],
    ));
    if (confirmed != true) return;
    try { await _service.deleteReading(reading.id); if (mounted) setState(_load); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(ServicePrice, List<UtilityReading>)>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: () => setState(_load));
        final (price, readings) = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Row(children: [
                Expanded(child: FilledButton.icon(onPressed: () => _openReadingForm(), icon: const Icon(Icons.add), label: const Text('Ghi chỉ số'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: widget.isManager ? () async { final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ServicePriceScreen(apiClient: widget.apiClient, price: price))); if (changed == true) setState(_load); } : null, icon: const Icon(Icons.settings), label: Text(widget.isManager ? 'Bảng giá' : 'Giá (chỉ xem)'))),
              ]),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFFEFF6FF),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Bảng giá hiện hành', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 18, runSpacing: 8, children: [
                      Text('Điện: ${formatCurrency(price.electricPrice)}/kWh'),
                      Text('Nước: ${formatCurrency(price.waterPrice)}/m³'),
                      Text('Dịch vụ: ${formatCurrency(price.serviceFee)}'),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Text('${readings.length} bản ghi gần nhất', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...readings.map((reading) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        onTap: () => _openReadingForm(reading),
                        leading: const CircleAvatar(child: Icon(Icons.bolt_rounded)),
                        title: Text('${reading.roomNumber} · ${reading.month.toString().padLeft(2, '0')}/${reading.year}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Điện ${reading.oldElectric} → ${reading.newElectric} (${reading.electricUsage})\nNước ${reading.oldWater} → ${reading.newWater} (${reading.waterUsage})'),
                        isThreeLine: true,
                        trailing: widget.isManager ? IconButton(onPressed: () => _delete(reading), icon: const Icon(Icons.delete_outline), tooltip: 'Xóa') : null,
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
