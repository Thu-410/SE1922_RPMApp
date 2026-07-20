class ServicePrice {
  const ServicePrice({
    required this.id,
    required this.electricPrice,
    required this.waterPrice,
    required this.serviceFee,
    required this.parkingFee,
    required this.internetFee,
    required this.effectiveDate,
    required this.isActive,
  });

  final int id;
  final double electricPrice;
  final double waterPrice;
  final double serviceFee;
  final double parkingFee;
  final double internetFee;
  final DateTime effectiveDate;
  final bool isActive;

  factory ServicePrice.fromJson(Map<String, dynamic> json) => ServicePrice(
    id: json['id'] as int,
    electricPrice: (json['electric_price'] as num).toDouble(),
    waterPrice: (json['water_price'] as num).toDouble(),
    serviceFee: (json['service_fee'] as num).toDouble(),
    parkingFee: (json['parking_fee'] as num).toDouble(),
    internetFee: (json['internet_fee'] as num).toDouble(),
    effectiveDate: DateTime.parse(json['effective_date'].toString()),
    isActive: json['is_active'] == true || json['is_active'] == 1,
  );
}
