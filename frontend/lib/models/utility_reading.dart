class UtilityReading {
  const UtilityReading({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    required this.month,
    required this.year,
    required this.oldElectric,
    required this.newElectric,
    required this.oldWater,
    required this.newWater,
    required this.electricUsage,
    required this.waterUsage,
    this.note,
  });

  final int id;
  final int roomId;
  final String roomNumber;
  final int month;
  final int year;
  final int oldElectric;
  final int newElectric;
  final int oldWater;
  final int newWater;
  final int electricUsage;
  final int waterUsage;
  final String? note;

  factory UtilityReading.fromJson(Map<String, dynamic> json) => UtilityReading(
    id: json['id'] as int,
    roomId: json['room_id'] as int,
    roomNumber: json['room_number']?.toString() ?? 'Phòng ${json['room_id']}',
    month: json['month'] as int,
    year: json['year'] as int,
    oldElectric: json['old_electric'] as int,
    newElectric: json['new_electric'] as int,
    oldWater: json['old_water'] as int,
    newWater: json['new_water'] as int,
    electricUsage: json['electric_usage'] as int,
    waterUsage: json['water_usage'] as int,
    note: json['note']?.toString(),
  );
}
