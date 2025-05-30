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

  // Ene hesgiig ashiglahgui
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
  // from JSON - fakestoreapi.com
  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
  // ProductModel --> JSON
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
  // JSON array --> list of ProductModel
  static List<ProductModel> fromList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  double get safePrice => price ?? 0.0;

  // ───────────────────────────────────────────────────────────────────────────
  // Firestore Map <---> ProductModel
  // ───────────────────────────────────────────────────────────────────────────
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
      // isFavorite-iig firestore deer hadgalsan tul unshina
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }

  // ProductModel --> map for Firestore
  // ingesneer Firestore-d hadgalj chadna
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
  // JSON --> Rating for FakeStore API
  factory Rating.fromJson(Map<String, dynamic> json) =>
      _$RatingFromJson(json);

  /// Rating --> JSON
  Map<String, dynamic> toJson() => _$RatingToJson(this);

  // ───────────────────────────────────────────────────────────────────────────
  // Firestore map <---> Rating
  // ───────────────────────────────────────────────────────────────────────────

  // Rating hesgiig uusgeh
  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      count: (map['count'] as num?)?.toInt() ?? 0,
    );
  }

  // Rating --> map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'rate': rate,
      'count': count,
    };
  }
}