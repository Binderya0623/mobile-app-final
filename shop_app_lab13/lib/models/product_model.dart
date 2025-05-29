// lib/models/product_model.dart

import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  final int? id;
  final String? title;
  final double? price;
  final String? description;
  final String? category;
  final String? image;
  final Rating? rating;

  /// This flag is only used client‐side to mark a product as “favorite.”
  /// We don't want json_serializable to include it when (de)serializing JSON
  /// from the FakeStore API, so we ignore it there.
  @JsonKey(ignore: true)
  bool isFavorite;

  ProductModel({
    this.id,
    this.title,
    this.price,
    this.description,
    this.category,
    this.image,
    this.rating,
    this.isFavorite = false,
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 1) JSON (FakeStore API) ↔ ProductModel
  // ───────────────────────────────────────────────────────────────────────────

  /// Create a ProductModel from JSON (as returned by fakestoreapi.com).
  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  /// Convert this ProductModel into JSON (for POST/PUT, if needed).
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  /// Helper: convert a raw JSON array into a list of ProductModel.
  static List<ProductModel> fromList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  double get safePrice => price ?? 0.0;

  // ───────────────────────────────────────────────────────────────────────────
  // 2) Firestore Map ↔ ProductModel
  // ───────────────────────────────────────────────────────────────────────────

  /// Create a ProductModel from a Firestore document’s data map.
  /// Assumes Firestore stored exactly these fields:
  /// {
  ///   'id': <int>,
  ///   'title': <String>,
  ///   'price': <double>,
  ///   'description': <String>,
  ///   'category': <String>,
  ///   'image': <String>,
  ///   'rating': { 'rate': <double>, 'count': <int> },   // optional
  ///   'isFavorite': <bool>
  /// }
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: (map['id'] as num?)?.toInt(),
      title: map['title'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      image: map['image'] as String? ?? '',
      rating: map['rating'] != null
          ? Rating.fromMap(Map<String, dynamic>.from(map['rating'] as Map))
          : null,
      // isFavorite is stored in Firestore, so read it here
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }

  /// Convert this ProductModel into a map so you can store it in Firestore.
  /// This does not use json_serializable, since we want to include isFavorite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'image': image,
      if (rating != null) 'rating': rating!.toMap(),
      'isFavorite': isFavorite,
    };
  }
}

@JsonSerializable()
class Rating {
  final double? rate;
  final int? count;

  Rating({this.rate, this.count});

  /// JSON → Rating for FakeStore API
  factory Rating.fromJson(Map<String, dynamic> json) =>
      _$RatingFromJson(json);

  /// Rating → JSON (if you ever POST/PUT)
  Map<String, dynamic> toJson() => _$RatingToJson(this);

  // ───────────────────────────────────────────────────────────────────────────
  // Firestore Map ↔ Rating
  // ───────────────────────────────────────────────────────────────────────────

  /// Create a Rating from a Firestore-stored map:
  /// { 'rate': <double>, 'count': <int> }
  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      count: (map['count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convert this Rating into a map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'rate': rate,
      'count': count,
    };
  }
}