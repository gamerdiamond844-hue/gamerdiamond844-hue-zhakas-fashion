class Order {
  final int id;
  final String status;
  final double totalAmount;
  final double discountAmount;
  final String? couponCode;
  final String? shippingName;
  final String? shippingAddress;
  final String? shippingPhone;
  final String? paymentProof;
  final DateTime? createdAt;

  Order({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.discountAmount,
    this.couponCode,
    this.shippingName,
    this.shippingAddress,
    this.shippingPhone,
    this.paymentProof,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'pending',
      totalAmount: (json['total_amount'] as num? ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] as num? ?? 0).toDouble(),
      couponCode: json['coupon_code'] as String?,
      shippingName: json['shipping_name'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      shippingPhone: json['shipping_phone'] as String?,
      paymentProof: json['payment_proof'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
