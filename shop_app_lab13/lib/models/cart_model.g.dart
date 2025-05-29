// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartModel _$CartModelFromJson(Map<String, dynamic> json) => CartModel(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  date: json['date'] as String,
  products:
      (json['products'] as List<dynamic>)
          .map((e) => CartProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$CartModelToJson(CartModel instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'date': instance.date,
  'products': instance.products,
};

CartProduct _$CartProductFromJson(Map<String, dynamic> json) => CartProduct(
  productId: (json['productId'] as num).toInt(),
  quantity: (json['quantity'] as num).toInt(),
);

Map<String, dynamic> _$CartProductToJson(CartProduct instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'quantity': instance.quantity,
    };
