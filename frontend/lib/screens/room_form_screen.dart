import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/room.dart';
import '../services/room_api_service.dart';

class RoomFormScreen extends StatefulWidget {
  const RoomFormScreen({super.key, required this.roomService, this.room});

  final RoomApiService roomService;
  final Room? room;

  bool get isEditing => room != null;

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _nameController;
  late final TextEditingController _floorController;
  late final TextEditingController _areaController;
  late final TextEditingController _priceController;
  late final TextEditingController _depositController;
  late final TextEditingController _descriptionController;
  late final List<TextEditingController> _imageControllers;
  final ImagePicker _imagePicker = ImagePicker();
  late RoomStatus _status;
  bool _saving = false;
  bool _uploadingImages = false;

  @override
  void initState() {
    super.initState();
    final room = widget.room;
    _numberController = TextEditingController(text: room?.roomNumber);
    _nameController = TextEditingController(text: room?.roomName);
    _floorController = TextEditingController(text: '${room?.floor ?? 1}');
    _areaController = TextEditingController(text: _numberText(room?.area));
    _priceController = TextEditingController(text: _numberText(room?.price));
    _depositController = TextEditingController(
      text: _numberText(room?.deposit),
    );
    _descriptionController = TextEditingController(text: room?.description);
    _imageControllers = (room?.images.isNotEmpty == true ? room!.images : [''])
        .map((image) => TextEditingController(text: image))
        .toList();
    _status = room?.status ?? RoomStatus.available;
  }

  String _numberText(double? number) {
    if (number == null) return '';
    return number == number.roundToDouble()
        ? number.round().toString()
        : number.toString();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _floorController.dispose();
    _areaController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _descriptionController.dispose();
    for (final controller in _imageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addImageField() {
    if (_imageControllers.length >= 10) return;
    setState(() => _imageControllers.add(TextEditingController()));
  }

  void _removeImageField(int index) {
    if (_imageControllers.length == 1) {
      _imageControllers.first.clear();
      return;
    }
    final controller = _imageControllers.removeAt(index);
    controller.dispose();
    setState(() {});
  }

  int get _filledImageCount => _imageControllers
      .where((controller) => controller.text.trim().isNotEmpty)
      .length;

  void _insertUploadedImage(String imageUrl) {
    final emptyIndex = _imageControllers.indexWhere(
      (controller) => controller.text.trim().isEmpty,
    );
    setState(() {
      if (emptyIndex >= 0) {
        _imageControllers[emptyIndex].text = imageUrl;
      } else if (_imageControllers.length < 10) {
        _imageControllers.add(TextEditingController(text: imageUrl));
      }
    });
  }

  void _showImageMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> _pickAndUploadImages() async {
    if (_saving || _uploadingImages) return;

    final remaining = 10 - _filledImageCount;
    if (remaining <= 0) {
      _showImageMessage('Mỗi phòng chỉ được có tối đa 10 ảnh.', error: true);
      return;
    }

    late final List<XFile> selectedImages;
    try {
      selectedImages = await _imagePicker.pickMultiImage();
    } on PlatformException catch (error) {
      _showImageMessage(
        error.message ?? 'Không thể mở thư viện ảnh trên thiết bị.',
        error: true,
      );
      return;
    } catch (_) {
      _showImageMessage(
        'Không thể mở thư viện ảnh trên thiết bị.',
        error: true,
      );
      return;
    }

    if (!mounted || selectedImages.isEmpty) return;

    final imagesToUpload = selectedImages.take(remaining).toList();
    var uploadedCount = 0;
    var failedCount = 0;
    setState(() => _uploadingImages = true);

    try {
      for (final image in imagesToUpload) {
        try {
          final length = await image.length();
          if (length > 5 * 1024 * 1024) {
            failedCount++;
            continue;
          }
          final imageUrl = await widget.roomService.uploadRoomImage(
            filename: image.name,
            bytes: await image.readAsBytes(),
          );
          if (!mounted) return;
          _insertUploadedImage(imageUrl);
          uploadedCount++;
        } catch (_) {
          failedCount++;
        }
      }
    } finally {
      if (mounted) setState(() => _uploadingImages = false);
    }

    if (!mounted) return;
    final ignoredCount = selectedImages.length - imagesToUpload.length;
    if (uploadedCount > 0 && failedCount == 0 && ignoredCount == 0) {
      _showImageMessage('Đã tải lên $uploadedCount ảnh.');
      return;
    }

    final details = <String>[
      if (uploadedCount > 0) '$uploadedCount ảnh đã tải lên',
      if (failedCount > 0) '$failedCount ảnh lỗi hoặc lớn hơn 5 MB',
      if (ignoredCount > 0) '$ignoredCount ảnh vượt giới hạn 10 ảnh',
    ];
    _showImageMessage(details.join(', '), error: failedCount > 0);
  }

  Future<void> _save() async {
    if (_saving || _uploadingImages) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final roomNumber = _numberController.text.trim();
    final roomName = _nameController.text.trim();
    final floor = int.tryParse(_floorController.text.trim());
    final area = _parsePositiveNumber(_areaController.text);
    final price = _parsePositiveNumber(_priceController.text);
    final deposit = _parsePositiveNumber(_depositController.text);

    if (floor == null ||
        floor < 0 ||
        area == null ||
        price == null ||
        deposit == null) {
      _formKey.currentState!.validate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Dữ liệu số không hợp lệ. Vui lòng kiểm tra tầng, diện tích, giá thuê và tiền cọc.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final input = RoomInput(
      roomNumber: roomNumber,
      roomName: roomName,
      floor: floor,
      area: area,
      price: price,
      deposit: deposit,
      status: _status,
      description: _descriptionController.text,
      expectedVersion: widget.room?.version,
      images: _imageControllers
          .map((controller) => controller.text.trim())
          .where((image) => image.isNotEmpty)
          .toList(),
    );

    setState(() => _saving = true);
    try {
      final saved = widget.isEditing
          ? await widget.roomService.updateRoom(widget.room!.id, input)
          : await widget.roomService.createRoom(input);
      if (!mounted) return;
      Navigator.pop(context, saved);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập thông tin này';
    }
    return null;
  }

  String? _nonNegativeInt(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number < 0) {
      return 'Giá trị phải là số nguyên từ 0';
    }
    return null;
  }

  double? _parsePositiveNumber(String value) {
    final number = double.tryParse(value.trim().replaceAll(',', '.'));
    return number != null && number.isFinite && number > 0 ? number : null;
  }

  String? _positiveNumber(String? value) {
    if (_parsePositiveNumber(value ?? '') == null) {
      return 'Giá trị phải là số lớn hơn 0';
    }
    return null;
  }

  String? _imageUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'URL ảnh phải bắt đầu bằng http:// hoặc https://';
    }
    if (value.trim().length > 500) return 'URL không được vượt quá 500 ký tự';
    const formats = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'avif'};
    final extension = uri.pathSegments.isEmpty
        ? ''
        : uri.pathSegments.last.split('.').last.toLowerCase();
    final queryFormat =
        (uri.queryParameters['fm'] ?? uri.queryParameters['format'] ?? '')
            .toLowerCase();
    if (!formats.contains(extension) &&
        !formats.contains(queryFormat) &&
        uri.host != 'images.unsplash.com') {
      return 'Chỉ nhận ảnh JPG, JPEG, PNG, WEBP, GIF hoặc AVIF';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Chỉnh sửa phòng' : 'Thêm phòng mới'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.isEditing
                          ? 'Cập nhật thông tin phòng ${widget.room!.roomNumber}'
                          : 'Điền đầy đủ thông tin để tạo phòng mới.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      title: 'Thông tin cơ bản',
                      children: [
                        _ResponsiveFields(
                          children: [
                            TextFormField(
                              controller: _numberController,
                              validator: (value) {
                                final error = _requiredText(value);
                                if (error != null) return error;
                                return value!.trim().length > 50
                                    ? 'Mã phòng không được vượt quá 50 ký tự'
                                    : null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Mã phòng *',
                                hintText: 'Ví dụ: P101',
                                prefixIcon: Icon(Icons.tag_outlined),
                              ),
                            ),
                            TextFormField(
                              controller: _nameController,
                              validator: (value) {
                                final error = _requiredText(value);
                                if (error != null) return error;
                                return value!.trim().length > 150
                                    ? 'Tên phòng không được vượt quá 150 ký tự'
                                    : null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Tên phòng *',
                                hintText: 'Ví dụ: Phòng ban công P101',
                                prefixIcon: Icon(Icons.meeting_room_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ResponsiveFields(
                          children: [
                            TextFormField(
                              controller: _floorController,
                              validator: _nonNegativeInt,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Tầng *',
                                prefixIcon: Icon(Icons.layers_outlined),
                              ),
                            ),
                            TextFormField(
                              controller: _areaController,
                              validator: _positiveNumber,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: const [
                                _DecimalInputFormatter(decimalPlaces: 2),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Diện tích (m²) *',
                                prefixIcon: Icon(Icons.square_foot_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<RoomStatus>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Trạng thái *',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: RoomStatus.values
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.label),
                                ),
                              )
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _status = value);
                                  }
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _Section(
                      title: 'Chi phí',
                      children: [
                        _ResponsiveFields(
                          children: [
                            TextFormField(
                              controller: _priceController,
                              validator: _positiveNumber,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Giá thuê (VNĐ/tháng) *',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                            ),
                            TextFormField(
                              controller: _depositController,
                              validator: _positiveNumber,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Tiền cọc (VNĐ) *',
                                prefixIcon: Icon(
                                  Icons.account_balance_wallet_outlined,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _Section(
                      title: 'Ảnh chi tiết',
                      children: [
                        const Text(
                          'Tải ảnh từ máy hoặc dán URL ảnh mạng. Tối đa 10 ảnh, mỗi ảnh tải lên không quá 5 MB. Ảnh đầu tiên là ảnh đại diện.',
                          style: TextStyle(color: Color(0xFF667085)),
                        ),
                        const SizedBox(height: 14),
                        for (
                          var index = 0;
                          index < _imageControllers.length;
                          index++
                        ) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _imageControllers[index],
                                  validator: _imageUrl,
                                  onChanged: (_) => setState(() {}),
                                  keyboardType: TextInputType.url,
                                  decoration: InputDecoration(
                                    labelText: 'Ảnh ${index + 1}',
                                    hintText: 'https://example.com/room.jpg',
                                    prefixIcon: const Icon(
                                      Icons.image_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Xóa ảnh này',
                                onPressed: () => _removeImageField(index),
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.red.shade600,
                              ),
                            ],
                          ),
                          if (index < _imageControllers.length - 1)
                            const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed:
                                  _uploadingImages || _filledImageCount >= 10
                                  ? null
                                  : _pickAndUploadImages,
                              icon: _uploadingImages
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.upload_file_outlined),
                              label: Text(
                                _uploadingImages
                                    ? 'Đang tải ảnh...'
                                    : 'Tải ảnh từ máy',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _imageControllers.length >= 10
                                  ? null
                                  : _addImageField,
                              icon: const Icon(Icons.add_link_outlined),
                              label: Text(
                                'Thêm URL ảnh ($_filledImageCount/10)',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _Section(
                      title: 'Mô tả phòng',
                      children: [
                        TextFormField(
                          controller: _descriptionController,
                          minLines: 5,
                          maxLines: 9,
                          decoration: const InputDecoration(
                            labelText: 'Mô tả',
                            hintText:
                                'Mô tả tiện nghi, vị trí, nội thất hoặc ghi chú về phòng...',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _saving || _uploadingImages
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _saving || _uploadingImages ? null : _save,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            widget.isEditing ? 'Lưu thay đổi' : 'Thêm phòng',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DecimalInputFormatter extends TextInputFormatter {
  const _DecimalInputFormatter({required this.decimalPlaces});

  final int decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final pattern = RegExp('^\\d*(?:[.,]\\d{0,$decimalPlaces})?\$');
    return pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) const SizedBox(height: 16),
                children[index],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(width: 16),
              Expanded(child: children[index]),
            ],
          ],
        );
      },
    );
  }
}
