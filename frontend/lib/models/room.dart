enum RoomStatus {
  available('available', 'Phòng trống'),
  occupied('occupied', 'Đang thuê'),
  maintenance('maintenance', 'Đang sửa chữa'),
  inactive('inactive', 'Ngừng sử dụng');

  const RoomStatus(this.value, this.label);

  final String value;
  final String label;

  static RoomStatus fromValue(Object? value) {
    if (value is! String) {
      throw const FormatException('Trạng thái phòng không hợp lệ.');
    }
    for (final status in RoomStatus.values) {
      if (status.value == value) return status;
    }
    throw FormatException('Trạng thái phòng không hợp lệ: $value');
  }
}

class Room {
  const Room({
    required this.id,
    required this.roomNumber,
    required this.roomName,
    required this.floor,
    required this.area,
    required this.price,
    required this.deposit,
    required this.status,
    required this.version,
    this.description,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String roomNumber;
  final String roomName;
  final int floor;
  final double area;
  final double price;
  final double deposit;
  final RoomStatus status;
  final int version;
  final String? description;
  final List<String> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get imageUrl => images.isEmpty ? null : images.first;

  factory Room.fromJson(Map<String, dynamic> json) {
    int requireInt(String key, {int minimum = 1}) {
      final value = json[key];
      final parsed = value is int ? value : int.tryParse('$value');
      if (parsed == null || parsed < minimum) {
        throw FormatException('$key không hợp lệ.');
      }
      return parsed;
    }

    double requirePositiveDouble(String key) {
      final value = json[key];
      final parsed = value is num
          ? value.toDouble()
          : double.tryParse('$value');
      if (parsed == null || !parsed.isFinite || parsed <= 0) {
        throw FormatException('$key không hợp lệ.');
      }
      return parsed;
    }

    String requireText(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('$key không hợp lệ.');
      }
      return value.trim();
    }

    DateTime? optionalDate(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String) throw FormatException('$key không hợp lệ.');
      final parsed = DateTime.tryParse(value);
      if (parsed == null) throw FormatException('$key không hợp lệ.');
      return parsed;
    }

    final roomNumber = requireText('room_number');
    final roomName = requireText('room_name');
    final rawImages = json['images'];
    if (rawImages != null && rawImages is! List) {
      throw const FormatException('Danh sách ảnh phòng không hợp lệ.');
    }
    final images = <String>[];
    for (final image in rawImages as List? ?? const []) {
      if (image is! String || image.trim().isEmpty) {
        throw const FormatException('URL ảnh phòng không hợp lệ.');
      }
      images.add(image.trim());
    }
    final legacyImage = json['image_url'];
    if (legacyImage != null && legacyImage is! String) {
      throw const FormatException('Ảnh đại diện phòng không hợp lệ.');
    }
    if (images.isEmpty &&
        legacyImage is String &&
        legacyImage.trim().isNotEmpty) {
      images.add(legacyImage.trim());
    }

    final description = json['description'];
    if (description != null && description is! String) {
      throw const FormatException('Mô tả phòng không hợp lệ.');
    }

    return Room(
      id: requireInt('id'),
      roomNumber: roomNumber,
      roomName: roomName,
      floor: requireInt('floor', minimum: 0),
      area: requirePositiveDouble('area'),
      price: requirePositiveDouble('price'),
      deposit: requirePositiveDouble('deposit'),
      status: RoomStatus.fromValue(json['status']),
      version: requireInt('version'),
      description: description as String?,
      images: List.unmodifiable(images),
      createdAt: optionalDate('created_at'),
      updatedAt: optionalDate('updated_at'),
    );
  }

  Room copyWith({RoomStatus? status}) => Room(
    id: id,
    roomNumber: roomNumber,
    roomName: roomName,
    floor: floor,
    area: area,
    price: price,
    deposit: deposit,
    status: status ?? this.status,
    version: version,
    description: description,
    images: images,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class RoomInput {
  const RoomInput({
    required this.roomNumber,
    required this.roomName,
    required this.floor,
    required this.area,
    required this.price,
    required this.deposit,
    required this.status,
    required this.images,
    this.description,
    this.expectedVersion,
  });

  final String roomNumber;
  final String roomName;
  final int floor;
  final double area;
  final double price;
  final double deposit;
  final RoomStatus status;
  final String? description;
  final List<String> images;
  final int? expectedVersion;

  Map<String, dynamic> toJson() => {
    'room_number': roomNumber.trim(),
    'room_name': roomName.trim(),
    'floor': floor,
    'area': area,
    'price': price,
    'deposit': deposit,
    'status': status.value,
    'description': _nullable(description),
    'images': images
        .map((image) => image.trim())
        .where((image) => image.isNotEmpty)
        .toList(),
    if (expectedVersion != null) 'expected_version': expectedVersion,
  };

  static String? _nullable(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
