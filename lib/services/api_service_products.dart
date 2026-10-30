import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/product_model.dart';

/// Service API untuk DummyJSON Products.
/// Dokumentasi: https://dummyjson.com/docs/products
class ApiServiceProducts {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://dummyjson.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  /// GET /products
  /// GET /products/search?q=
  /// GET /products/category/{slug}
  ///
  /// Mendukung pencarian, kategori, sorting, dan pagination.
  Future<ProductsResponse> getProducts({
    String query = '',
    String category = '',
    String? sortBy,
    String order = 'asc',
    int limit = 30,
    int skip = 0,
  }) async {
    String path = '/products';

    final params = <String, dynamic>{
      'limit': limit,
      'skip': skip,
    };

    if (query.trim().isNotEmpty) {
      path = '/products/search';
      params['q'] = query.trim();
    } else if (category.trim().isNotEmpty) {
      path = '/products/category/${category.trim()}';
    }

    if (sortBy != null && sortBy.isNotEmpty) {
      params['sortBy'] = sortBy;
      params['order'] = order;
    }

    try {
      final res = await _dio.get(
        path,
        queryParameters: params,
      );

      debugPrint('========== GET PRODUCTS ==========');
      debugPrint('URL API: ${res.realUri}');
      debugPrint('STATUS API: ${res.statusCode}');

      final result = ProductsResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );

      debugPrint('TOTAL PRODUK API: ${result.total}');
      debugPrint(
        'JUMLAH PRODUK TERBACA: ${result.products.length}',
      );

      if (result.products.isNotEmpty) {
        debugPrint(
          'PRODUK PERTAMA: ${result.products.first.title}',
        );
      }

      debugPrint('==================================');

      return result;
    } on DioException catch (e) {
      debugPrint('========== ERROR API ==========');
      debugPrint('URL ERROR: ${e.requestOptions.uri}');
      debugPrint('PESAN ERROR: ${e.message}');
      debugPrint('STATUS ERROR: ${e.response?.statusCode}');
      debugPrint('DATA ERROR: ${e.response?.data}');
      debugPrint('================================');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('========== ERROR PARSING ==========');
      debugPrint('PESAN: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('===================================');

      rethrow;
    }
  }

  /// GET /products?limit=10&skip=10&select=title,price
  Future<ProductsResponse> getProductsPaginated({
    int limit = 10,
    int skip = 0,
    String? select,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'skip': skip,
    };

    if (select != null && select.isNotEmpty) {
      params['select'] = select;
    }

    try {
      final res = await _dio.get(
        '/products',
        queryParameters: params,
      );

      return ProductsResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } catch (e) {
      debugPrint('ERROR GET PRODUCTS PAGINATED: $e');
      rethrow;
    }
  }

  /// GET /products/{id}
  Future<Product> getProduct(int id) async {
    try {
      final res = await _dio.get('/products/$id');

      return Product.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } catch (e) {
      debugPrint('ERROR GET PRODUCT $id: $e');
      rethrow;
    }
  }

  /// GET /products/search?q=
  Future<ProductsResponse> searchProducts(String query) async {
    try {
      final res = await _dio.get(
        '/products/search',
        queryParameters: {
          'q': query,
        },
      );

      return ProductsResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } catch (e) {
      debugPrint('ERROR SEARCH PRODUCTS: $e');
      rethrow;
    }
  }

  /// GET /products?sortBy=&order=
  Future<ProductsResponse> sortProducts(
    String sortBy,
    String order,
  ) async {
    try {
      final res = await _dio.get(
        '/products',
        queryParameters: {
          'sortBy': sortBy,
          'order': order,
        },
      );

      return ProductsResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } catch (e) {
      debugPrint('ERROR SORT PRODUCTS: $e');
      rethrow;
    }
  }

  /// GET /products/categories
  Future<List<Category>> getCategories() async {
    try {
      final res = await _dio.get('/products/categories');

      final data = res.data as List;

      return data.map((e) {
        return Category.fromJson(
          Map<String, dynamic>.from(e as Map),
        );
      }).toList();
    } catch (e) {
      debugPrint('ERROR GET CATEGORIES: $e');
      rethrow;
    }
  }

  /// GET /products/category-list
  Future<List<String>> getCategoryList() async {
    try {
      final res = await _dio.get('/products/category-list');

      return (res.data as List)
          .map((e) => e.toString())
          .toList();
    } catch (e) {
      debugPrint('ERROR GET CATEGORY LIST: $e');
      rethrow;
    }
  }

  /// GET /products/category/{slug}
  Future<ProductsResponse> getProductsByCategory(
    String category,
  ) async {
    try {
      final res = await _dio.get(
        '/products/category/$category',
      );

      return ProductsResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } catch (e) {
      debugPrint('ERROR GET PRODUCTS BY CATEGORY: $e');
      rethrow;
    }
  }

  /// POST /products/add
  /// DummyJSON hanya menyimulasikan penambahan produk.
  Future<Product> addProduct(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.post(
        '/products/add',
        data: data,
      );

      return Product.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } catch (e) {
      debugPrint('ERROR ADD PRODUCT: $e');
      rethrow;
    }
  }

  /// PUT /products/{id}
  /// Update penuh; perubahan hanya simulasi.
  Future<Product> updateProduct(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.put(
        '/products/$id',
        data: data,
      );

      return Product.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } catch (e) {
      debugPrint('ERROR UPDATE PRODUCT $id: $e');
      rethrow;
    }
  }

  /// PATCH /products/{id}
  /// Update sebagian; perubahan hanya simulasi.
  Future<Product> patchProduct(
    int id,
    Map<String, dynamic> partialData,
  ) async {
    try {
      final res = await _dio.patch(
        '/products/$id',
        data: partialData,
      );

      return Product.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } catch (e) {
      debugPrint('ERROR PATCH PRODUCT $id: $e');
      rethrow;
    }
  }

  /// DELETE /products/{id}
  /// Penghapusan hanya simulasi.
  Future<Product> deleteProduct(int id) async {
    try {
      final res = await _dio.delete(
        '/products/$id',
      );

      return Product.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } catch (e) {
      debugPrint('ERROR DELETE PRODUCT $id: $e');
      rethrow;
    }
  }
}
