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
    this.activeTenantCount = 0,
  });

  final int id;
  final String roomNumber;
  final int floor;
  final double area;
  final double price;
  final double deposit;
  final String status;
  final String? description;
  final String? imageUrl;
  final int activeTenantCount;

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: int.tryParse('${json['id']}') ?? 0,
    roomNumber: json['room_number']?.toString() ?? '',
    floor: int.tryParse('${json['floor']}') ?? 0,
    area: double.tryParse('${json['area']}') ?? 0,
    price: double.tryParse('${json['price']}') ?? 0,
    deposit: double.tryParse('${json['deposit']}') ?? 0,
    status: json['status']?.toString() ?? 'available',
    description: json['description']?.toString(),
    imageUrl: json['image_url']?.toString(),
    activeTenantCount: int.tryParse('${json['active_tenant_count']}') ?? 0,
  );
}

const roomStatuses = ['available', 'occupied', 'maintenance', 'inactive'];

String roomStatusLabel(String status) => switch (status) {
  'available' => 'Còn trống',
  'occupied' => 'Đang thuê',
  'maintenance' => 'Bảo trì',
  'inactive' => 'Ngừng hoạt động',
  _ => status,
};
