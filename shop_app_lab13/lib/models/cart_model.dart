import 'package:json_annotation/json_annotation.dart';
part 'cart_model.g.dart';

@JsonSerializable()
class CartModel {
  final int id;
  final int userId;
  final String date;
  final List<CartProduct> products;

  CartModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.products,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) => _$CartModelFromJson(json);
  Map<String, dynamic> toJson() => _$CartModelToJson(this);

  static List<CartModel> fromList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => CartModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

@JsonSerializable()
class CartProduct {
  final int productId;
  final int quantity;
  CartProduct({
    required this.productId,
    required this.quantity,
  });
  factory CartProduct.fromJson(Map<String, dynamic> json) => _$CartProductFromJson(json);
  Map<String, dynamic> toJson() => _$CartProductToJson(this);
} 