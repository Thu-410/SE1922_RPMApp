class RoomOption {
  const RoomOption({required this.id, required this.roomNumber, required this.status});
  final int id;
  final String roomNumber;
  final String status;

  factory RoomOption.fromJson(Map<String, dynamic> json) => RoomOption(
        id: json['id'] as int,
        roomNumber: json['room_number'].toString(),
        status: json['status'].toString(),
      );
}
