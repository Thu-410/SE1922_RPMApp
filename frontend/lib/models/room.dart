enum RoomStatus {
  available('available', 'Còn trống'),
  occupied('occupied', 'Đang thuê'),
  maintenance('maintenance', 'Bảo trì'),
  inactive('inactive', 'Ngừng hoạt động');

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
    required this.floor,
    required this.area,
    required this.price,
    required this.deposit,
    required this.status,
    this.description,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String roomNumber;
  final int floor;
  final double area;
  final double price;
  final double deposit;
  final RoomStatus status;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Room.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    int parseInt(dynamic value) =>
        value is int ? value : int.tryParse('$value') ?? 0;

    return Room(
      id: parseInt(json['id']),
      roomNumber: '${json['room_number'] ?? ''}',
      floor: parseInt(json['floor']),
      area: parseDouble(json['area']),
      price: parseDouble(json['price']),
      deposit: parseDouble(json['deposit']),
      status: RoomStatus.fromValue(json['status'] as String?),
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  Map<String, dynamic> toPayload() => {
    'room_number': roomNumber,
    'floor': floor,
    'area': area,
    'price': price,
    'deposit': deposit,
    'status': status.value,
    'description': description,
    'image_url': imageUrl,
  };

  Room copyWith({RoomStatus? status}) => Room(
    id: id,
    roomNumber: roomNumber,
    floor: floor,
    area: area,
    price: price,
    deposit: deposit,
    status: status ?? this.status,
    description: description,
    imageUrl: imageUrl,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class RoomInput {
  const RoomInput({
    required this.roomNumber,
    required this.floor,
    required this.area,
    required this.price,
    required this.deposit,
    required this.status,
    this.description,
    this.imageUrl,
  });

  final String roomNumber;
  final int floor;
  final double area;
  final double price;
  final double deposit;
  final RoomStatus status;
  final String? description;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
    'room_number': roomNumber.trim(),
    'floor': floor,
    'area': area,
    'price': price,
    'deposit': deposit,
    'status': status.value,
    'description': _nullable(description),
    'image_url': _nullable(imageUrl),
  };

  static String? _nullable(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
