class Food {
  final int id;
  final int categoryId;

  final String name;
  final String? description;

  final double price;

  final String? thumbnailUrl;

  final String status;

  Food({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.thumbnailUrl,
    required this.status,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      thumbnailUrl: json['thumbnail_url'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'thumbnail_url': thumbnailUrl,
      'status': status,
    };
  }
}
