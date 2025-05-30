import '../services/httpService.dart';
import '../models/product_model.dart';

class MyRepository {
  final HttpService httpService;
  
  MyRepository({required this.httpService});

  Future<List<ProductModel>> getProducts() async {
    try {
      print('Fetching products from repository');
      final jsonData = await httpService.getData('products', null);
      print('Products fetched successfully');
      return ProductModel.fromList(jsonData);
    } catch (e) {
      print('Error fetching products: $e');
      throw Exception('Failed to load products: $e');
    }
  }

  Future<ProductModel> getProduct(int productId) async {
    try {
      print('Fetching product details for ID: $productId');
      final jsonData = await httpService.getData('products/$productId', null);
      print('Product details fetched successfully');
      return ProductModel.fromJson(jsonData);
    } catch (e) {
      print('Error fetching product details: $e');
      throw Exception('Failed to load product details: $e');
    }
  }
}