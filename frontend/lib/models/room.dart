enum RoomStatus {
  available('available', 'Phòng trống'),
  occupied('occupied', 'Đang thuê'),
  maintenance('maintenance', 'Đang sửa chữa'),
  inactive('inactive', 'Ngừng sử dụng');

  const RoomStatus(this.value, this.label);

  final String value;
  final String label;

  static RoomStatus fromValue(String? value) {
    return RoomStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RoomStatus.inactive,
    );
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
  final String? description;
  final List<String> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get imageUrl => images.isEmpty ? null : images.first;

  factory Room.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    int parseInt(dynamic value) =>
        value is int ? value : int.tryParse('$value') ?? 0;

    final roomNumber = '${json['room_number'] ?? ''}';
    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages
              .whereType<String>()
              .map((image) => image.trim())
              .where((image) => image.isNotEmpty)
              .toList()
        : <String>[];
    final legacyImage = json['image_url'];
    if (images.isEmpty &&
        legacyImage is String &&
        legacyImage.trim().isNotEmpty) {
      images.add(legacyImage.trim());
    }

    return Room(
      id: parseInt(json['id']),
      roomNumber: roomNumber,
      roomName: '${json['room_name'] ?? 'Phòng $roomNumber'}',
      floor: parseInt(json['floor']),
      area: parseDouble(json['area']),
      price: parseDouble(json['price']),
      deposit: parseDouble(json['deposit']),
      status: RoomStatus.fromValue(json['status'] as String?),
      description: json['description'] as String?,
      images: List.unmodifiable(images),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
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
  };

  static String? _nullable(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
