class Product {
  final int id;
  final String title;
  final String? description;
  final double price;
  final double discount;
  final int stock;
  final List<String> images;
  final String? videoUrl;
  final List<String> sizes;
  final List<String> colors;
  final bool isTrending;
  final bool isFeatured;
  final int? categoryId;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.discount,
    required this.stock,
    required this.images,
    this.description,
    this.videoUrl,
    this.sizes = const [],
    this.colors = const [],
    this.isTrending = false,
    this.isFeatured = false,
    this.categoryId,
  });

  double get discountedPrice => price - discount;
  int get discountPercent => discount > 0 ? ((discount / price) * 100).round() : 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      discount: (json['discount'] as num? ?? 0).toDouble(),
      stock: json['stock'] as int? ?? 0,
      images: List<String>.from(json['images'] as List? ?? []),
      videoUrl: json['video_url'] as String?,
      sizes: List<String>.from(json['sizes'] as List? ?? []),
      colors: List<String>.from(json['colors'] as List? ?? []),
      isTrending: json['is_trending'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      categoryId: json['category_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'discount': discount,
    'stock': stock,
    'images': images,
    'video_url': videoUrl,
    'sizes': sizes,
    'colors': colors,
    'is_trending': isTrending,
    'is_featured': isFeatured,
    'category_id': categoryId,
  };
}
