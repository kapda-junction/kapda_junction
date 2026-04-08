import 'package:equatable/equatable.dart';

class Coupon extends Equatable {
  final String id;
  final String code;
  final String description;
  /// `percentage` or `fixed`
  final String type;
  final double value;
  final double minCartValue;
  final double? maxDiscountAmount;
  final bool firstOrderOnly;
  final String? restrictedUserId;
  final int? usageLimitTotal;
  final int usageLimitPerUser;
  final int usedCount;
  final List<String> categoryIds;
  final List<String> productIds;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;

  const Coupon({
    required this.id,
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    required this.minCartValue,
    this.maxDiscountAmount,
    required this.firstOrderOnly,
    this.restrictedUserId,
    this.usageLimitTotal,
    required this.usageLimitPerUser,
    required this.usedCount,
    required this.categoryIds,
    required this.productIds,
    this.startsAt,
    this.endsAt,
    required this.isActive,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    List<String> idsOf(String key) {
      final raw = json[key] as List?;
      if (raw == null) return [];
      return raw.map((e) {
        if (e is Map && e['_id'] != null) return e['_id'].toString();
        return e.toString();
      }).toList();
    }

    final ru = json['restrictedUser'];
    String? ruId;
    if (ru is Map && ru['_id'] != null) {
      ruId = ru['_id'].toString();
    } else if (ru != null) {
      ruId = ru.toString();
    }

    return Coupon(
      id: json['_id'].toString(),
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? 'percentage',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      minCartValue: (json['minCartValue'] as num?)?.toDouble() ?? 0,
      maxDiscountAmount: (json['maxDiscountAmount'] as num?)?.toDouble(),
      firstOrderOnly: json['firstOrderOnly'] == true,
      restrictedUserId: ruId,
      usageLimitTotal: (json['usageLimitTotal'] as num?)?.toInt(),
      usageLimitPerUser: (json['usageLimitPerUser'] as num?)?.toInt() ?? 1,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      categoryIds: idsOf('categoryIds'),
      productIds: idsOf('productIds'),
      startsAt: json['startsAt'] != null
          ? DateTime.tryParse(json['startsAt'].toString())
          : null,
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(json['endsAt'].toString())
          : null,
      isActive: json['isActive'] != false,
    );
  }

  @override
  List<Object?> get props => [id];
}
