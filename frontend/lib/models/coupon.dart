class Coupon {
  final String code;
  final String discountType;
  final double discountValue;
  final double minimumOrderValue;
  final double? maximumDiscount;
  final bool firstTimeUser;

  Coupon({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minimumOrderValue,
    this.maximumDiscount,
    required this.firstTimeUser,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      code: json['code'],
      discountType: json['discount_type'],
      discountValue: (json['discount_value'] as num).toDouble(),
      minimumOrderValue: (json['minimum_order_value'] as num).toDouble(),
      maximumDiscount: json['maximum_discount'] != null ? (json['maximum_discount'] as num).toDouble() : null,
      firstTimeUser: json['first_time_user'] ?? false,
    );
  }
}
