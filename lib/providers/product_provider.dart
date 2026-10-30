import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/api_service_products.dart';

/// Error yang pesannya sudah ramah dibaca pengguna.
class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}

class ProductProvider extends ChangeNotifier {
  static const int pageSize = 30;
  final ApiServiceProducts _api = ApiServiceProducts();

  List<Product> _products = [];
  List<String> _categoryList = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _total = 0; // total dari server (194 untuk semua produk)
  int _serverLoaded = 0; // jumlah data yang sudah diambil dari server (untuk skip)
  int _hidden = 0; // jumlah produk terhapus yang disembunyikan di tampilan ini

  String _query = '';
  String _category = '';
  String? _sortBy;
  String _order = 'asc';
  int _requestId = 0; // mencegah hasil request lama menimpa yang baru

  // DummyJSON hanya MOCK: add/update/delete tidak tersimpan di server.
  // Agar perubahan tetap terlihat di aplikasi, perubahan disimpan di sini.
  final List<Product> _added = [];
  final Map<int, Product> _edited = {};
  final Set<int> _deletedIds = {};
  int _lastAddedId = 0;

  List<Product> get products => _products;
  List<String> get categoryList => _categoryList;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  int get total => _total;
  String get query => _query;
  String get selectedCategory => _category;
  String? get sortBy => _sortBy;
  String get order => _order;
  bool get hasMore => _serverLoaded < _total;

  /// Total yang ditampilkan di UI (sudah memperhitungkan tambah/hapus lokal).
  int get displayTotal =>
      math.max(_products.length, _total + _matchingAdded().length - _hidden);

  /// Produk hasil tambah/edit lokal (dipakai halaman detail agar tidak GET ke server).
  Product? localProduct(int id) {
    for (final p in _added) {
      if (p.id == id) return p;
    }
    return _edited[id];
  }

  bool _isAdded(int id) => _added.any((p) => p.id == id);

  // ---------------------------------------------------------------- READ
  Future<void> init() async {
    await Future.wait([fetchCategories(), fetchProducts()]);
  }

  Future<void> fetchCategories() async {
    try {
      _categoryList = await _api.getCategoryList(); // GET /products/category-list
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchProducts() async {
    final id = ++_requestId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.getProducts(
        query: _query,
        category: _category,
        sortBy: _sortBy,
        order: _order,
        limit: pageSize,
        skip: 0,
      );
      if (id != _requestId) return;
      _hidden = 0;
      _serverLoaded = res.products.length;
      _products = [..._matchingAdded(), ..._applyLocal(res.products)];
      _total = res.total;
    } catch (e) {
      if (id != _requestId) return;
      _error = _msg(e);
      _products = [];
      _total = 0;
      _serverLoaded = 0;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasMore) return;
    final id = _requestId;
    _loadingMore = true;
    notifyListeners();
    try {
      final res = await _api.getProducts(
        query: _query,
        category: _category,
        sortBy: _sortBy,
        order: _order,
        limit: pageSize,
        skip: _serverLoaded,
      );
      if (id == _requestId) {
        _serverLoaded += res.products.length;
        _products = [..._products, ..._applyLocal(res.products)];
        _total = res.total;
      }
    } catch (_) {}
    _loadingMore = false;
    notifyListeners();
  }

  Future<void> search(String q) {
    _query = q;
    return fetchProducts();
  }

  Future<void> setQueryAndCategory(String q, String category) {
    _query = q;
    _category = category;
    return fetchProducts();
  }

  Future<void> filterByCategory(String category) {
    _category = category;
    return fetchProducts();
  }

  Future<void> setSort(String? sortBy, String order) {
    _sortBy = sortBy;
    _order = order;
    return fetchProducts();
  }

  // -------------------------------------------------------------- CREATE
  /// POST /products/add
  Future<Product> addProduct(Product draft) async {
    try {
      final res = await _api.addProduct(draft.toJson());
      // Server selalu mengembalikan id 195, jadi id dibuat unik di sisi aplikasi.
      final newId = res.id > _lastAddedId ? res.id : _lastAddedId + 1;
      _lastAddedId = newId;
      final saved = draft.copyWith(id: newId);
      _added.insert(0, saved);
      if (_matches(saved)) _products = [saved, ..._products];
      notifyListeners();
      return saved;
    } catch (e) {
      throw AppException(_msg(e));
    }
  }

  // -------------------------------------------------------------- UPDATE
  /// PUT /products/{id}
  Future<Product> updateProduct(int id, Product updated) async {
    try {
      if (_isAdded(id)) {
        // Produk baru dari "add" tidak ada di server (404), jadi cukup lokal.
        final i = _added.indexWhere((p) => p.id == id);
        _added[i] = updated;
      } else {
        await _api.updateProduct(id, updated.toJson());
        _edited[id] = updated;
      }
      final idx = _products.indexWhere((p) => p.id == id);
      if (idx != -1) _products[idx] = updated;
      notifyListeners();
      return updated;
    } catch (e) {
      throw AppException(_msg(e));
    }
  }

  // -------------------------------------------------------------- DELETE
  /// DELETE /products/{id}
  Future<void> deleteProduct(int id) async {
    try {
      if (_isAdded(id)) {
        _added.removeWhere((p) => p.id == id);
      } else {
        await _api.deleteProduct(id);
        _deletedIds.add(id);
        _edited.remove(id);
      }
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      throw AppException(_msg(e));
    }
  }

  // ------------------------------------------------------------- helpers
  /// Terapkan edit & hapus lokal ke data baru dari server.
  List<Product> _applyLocal(List<Product> raw) {
    final out = <Product>[];
    for (final p in raw) {
      if (_deletedIds.contains(p.id)) {
        _hidden++;
        continue;
      }
      out.add(_edited[p.id] ?? p);
    }
    return out;
  }

  bool _matches(Product p) {
    if (_category.isNotEmpty && p.category != _category) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return p.title.toLowerCase().contains(q) ||
        p.brand.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q);
  }

  List<Product> _matchingAdded() => _added.where(_matches).toList();

  String _msg(Object e) {
    if (e is AppException) return e.message;
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Tidak bisa terhubung ke internet.\nPeriksa koneksi kamu.';
      }
      return 'Terjadi kesalahan server (${e.response?.statusCode ?? '-'}).';
    }
    return 'Terjadi kesalahan: $e';
  }
}
