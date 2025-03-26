// lib/data/models/order_model.dart
import 'package:uuid/uuid.dart';

enum OrderStatus {
  pending,      // Initial state when order is created
  paid,         // Payment has been processed successfully
  processing,   // Order is being prepared
  shipped,      // Order has been shipped
  delivered,    // Order has been delivered
  cancelled,    // Order was cancelled
  refunded      // Order was refunded
}

enum PaymentMethod {
  creditCard,
  paypal,
  mobilePayment,
  bankTransfer
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final double tax;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final Map<String, dynamic> shippingAddress;
  final String paymentMethod;
  final String? paymentId;
  final String? trackingNumber;
  final String? notes;
  
  Order({
    String? id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.tax,
    required this.total,
    this.status = OrderStatus.pending,
    DateTime? createdAt,
    this.paidAt,
    this.shippedAt,
    this.deliveredAt,
    required this.shippingAddress,
    required this.paymentMethod,
    this.paymentId,
    this.trackingNumber,
    this.notes,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'subtotal': subtotal,
      'shipping_fee': shippingFee,
      'tax': tax,
      'total': total,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'shipped_at': shippedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'shipping_address': shippingAddress,
      'payment_method': paymentMethod,
      'payment_id': paymentId,
      'tracking_number': trackingNumber,
      'notes': notes,
    };
  }
  
  factory Order.fromMap(Map<String, dynamic> map, {List<OrderItem>? orderItems}) {
    return Order(
      id: map['id'],
      userId: map['user_id'],
      items: orderItems ?? [],
      subtotal: (map['subtotal'] as num).toDouble(),
      shippingFee: (map['shipping_fee'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      status: _stringToOrderStatus(map['status']),
      createdAt: DateTime.parse(map['created_at']),
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at']) : null,
      shippedAt: map['shipped_at'] != null ? DateTime.parse(map['shipped_at']) : null,
      deliveredAt: map['delivered_at'] != null ? DateTime.parse(map['delivered_at']) : null,
      shippingAddress: Map<String, dynamic>.from(map['shipping_address']),
      paymentMethod: map['payment_method'],
      paymentId: map['payment_id'],
      trackingNumber: map['tracking_number'],
      notes: map['notes'],
    );
  }
  
  static OrderStatus _stringToOrderStatus(String status) {
    switch (status) {
      case 'pending': return OrderStatus.pending;
      case 'paid': return OrderStatus.paid;
      case 'processing': return OrderStatus.processing;
      case 'shipped': return OrderStatus.shipped;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      case 'refunded': return OrderStatus.refunded;
      default: return OrderStatus.pending;
    }
  }
  
  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? subtotal,
    double? shippingFee,
    double? tax,
    double? total,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? paidAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    Map<String, dynamic>? shippingAddress,
    String? paymentMethod,
    String? paymentId,
    String? trackingNumber,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      notes: notes ?? this.notes,
    );
  }
  
  String get statusText {
    switch (status) {
      case OrderStatus.pending: return 'Pending';
      case OrderStatus.paid: return 'Paid';
      case OrderStatus.processing: return 'Processing';
      case OrderStatus.shipped: return 'Shipped';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
      case OrderStatus.refunded: return 'Refunded';
    }
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String itemId;
  final String itemType; // 'auction' or 'fixed_price'
  final String title;
  final double price;
  final int quantity;
  final double total;
  final String? imageUrl;
  
  OrderItem({
    String? id,
    required this.orderId,
    required this.itemId,
    required this.itemType,
    required this.title,
    required this.price,
    required this.quantity,
    required this.total,
    this.imageUrl,
  }) : id = id ?? const Uuid().v4();
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'item_id': itemId,
      'item_type': itemType,
      'title': title,
      'price': price,
      'quantity': quantity,
      'total': total,
      'image_url': imageUrl,
    };
  }
  
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      itemId: map['item_id'],
      itemType: map['item_type'],
      title: map['title'],
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'],
      total: (map['total'] as num).toDouble(),
      imageUrl: map['image_url'],
    );
  }
}