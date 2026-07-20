import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/helpers/formatters.dart';
import '../../core/network/api_client.dart';
import '../../models/invoice.dart';
import '../../models/room_option.dart';
import '../../services/invoice_service.dart';
import '../../services/utility_service.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key, required this.apiClient, this.invoice});
  final ApiClient apiClient;
  final Invoice? invoice;

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _key = GlobalKey<FormState>();
  late final InvoiceService _invoiceService;
  late final UtilityService _utilityService;
  late final TextEditingController _otherFee;
  late final TextEditingController _otherName;
  late final TextEditingController _discount;
  late final TextEditingController _note;
  List<RoomOption> _rooms = [];
  int? _roomId;
  late int _month;
  late int _year;
  late DateTime _dueDate;
  late bool _service;
  late bool _parking;
  late bool _internet;
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _preview;

  bool get _editing => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    _invoiceService = InvoiceService(widget.apiClient);
    _utilityService = UtilityService(widget.apiClient);
    final invoice = widget.invoice;
    final now = DateTime.now();
    _roomId = invoice?.roomId;
    _month = invoice?.month ?? now.month;
    _year = invoice?.year ?? now.year;
    _dueDate = invoice?.dueDate ?? DateTime(now.year, now.month + 1, 5);
    _service = invoice == null || invoice.serviceFee > 0;
    _parking = invoice != null && invoice.parkingFee > 0;
    _internet = invoice == null || invoice.internetFee > 0;
    _otherFee = TextEditingController(
      text: invoice?.otherFee.toStringAsFixed(0) ?? '0',
    );
    _otherName = TextEditingController(text: 'Phí khác');
    _discount = TextEditingController(
      text: invoice?.discount.toStringAsFixed(0) ?? '0',
    );
    _note = TextEditingController(text: invoice?.note ?? '');
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      _rooms = await _utilityService.getRoomOptions();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [_otherFee, _otherName, _discount, _note]) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _body() => {
    'roomId': _roomId,
    'month': _month,
    'year': _year,
    'includeService': _service,
    'includeParking': _parking,
    'includeInternet': _internet,
    'otherFee': double.tryParse(_otherFee.text) ?? 0,
    'otherFeeName': _otherName.text.trim(),
    'discount': double.tryParse(_discount.text) ?? 0,
    'dueDate': _dueDate.toIso8601String().substring(0, 10),
    'note': _note.text.trim(),
  };

  Future<void> _previewInvoice() async {
    if (!_key.currentState!.validate() || _roomId == null) return;
    setState(() => _saving = true);
    try {
      final result = await _invoiceService.previewInvoice(_body());
      if (mounted) setState(() => _preview = result);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate() || _roomId == null) return;
    setState(() => _saving = true);
    try {
      if (_editing) {
        await _invoiceService.updateInvoice(widget.invoice!.id, _body());
      } else {
        await _invoiceService.createInvoice(_body());
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(_year, _month),
      lastDate: DateTime(_year + 2),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Sửa hóa đơn' : 'Tạo hóa đơn')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _key,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _roomId,
                    decoration: const InputDecoration(
                      labelText: 'Phòng',
                      border: OutlineInputBorder(),
                    ),
                    items: _rooms
                        .where(
                          (r) =>
                              !['maintenance', 'inactive'].contains(r.status) ||
                              r.id == _roomId,
                        )
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(r.roomNumber),
                          ),
                        )
                        .toList(),
                    onChanged: _editing
                        ? null
                        : (value) => setState(() {
                            _roomId = value;
                            _preview = null;
                          }),
                    validator: (value) => value == null ? 'Chọn phòng' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _month,
                          decoration: const InputDecoration(
                            labelText: 'Tháng',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(
                            12,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('${i + 1}'),
                            ),
                          ),
                          onChanged: _editing
                              ? null
                              : (v) => setState(() {
                                  _month = v!;
                                  _preview = null;
                                }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _year,
                          decoration: const InputDecoration(
                            labelText: 'Năm',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(
                            5,
                            (i) => DropdownMenuItem(
                              value: DateTime.now().year - 1 + i,
                              child: Text('${DateTime.now().year - 1 + i}'),
                            ),
                          ),
                          onChanged: _editing
                              ? null
                              : (v) => setState(() {
                                  _year = v!;
                                  _preview = null;
                                }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Phí dịch vụ'),
                    value: _service,
                    onChanged: (v) => setState(() {
                      _service = v;
                      _preview = null;
                    }),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Phí gửi xe'),
                    value: _parking,
                    onChanged: (v) => setState(() {
                      _parking = v;
                      _preview = null;
                    }),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Phí Internet'),
                    value: _internet,
                    onChanged: (v) => setState(() {
                      _internet = v;
                      _preview = null;
                    }),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _otherFee,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Phí khác',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _discount,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Giảm giá',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _otherName,
                    decoration: const InputDecoration(
                      labelText: 'Tên phí khác',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hạn thanh toán'),
                    subtitle: Text(formatDate(_dueDate)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: _pickDate,
                  ),
                  TextFormField(
                    controller: _note,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _previewInvoice,
                    icon: const Icon(Icons.calculate),
                    label: const Text('Tính và xem trước'),
                  ),
                  if (_preview != null) _PreviewCard(data: _preview!),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saving || (!_editing && _preview == null)
                        ? null
                        : _save,
                    icon: const Icon(Icons.save),
                    label: Text(
                      _saving
                          ? 'Đang xử lý...'
                          : _editing
                          ? 'Lưu thay đổi'
                          : 'Phát hành hóa đơn',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final calculation = data['calculation'] as Map<String, dynamic>;
    final items = calculation['items'] as List<dynamic>;
    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: const Color(0xFFF0FDF4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Kết quả tính',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ...items.map((raw) {
              final item = raw as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item['itemName'].toString())),
                    Text(formatCurrency(item['amount'] as num)),
                  ],
                ),
              );
            }),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatCurrency(calculation['totalAmount'] as num),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
