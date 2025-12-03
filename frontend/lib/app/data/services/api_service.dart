import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/app/data/models/product.dart';

class ApiService {
  // Configurado para rodar no Linux Desktop (127.0.0.1 é mais seguro que localhost)
  static const String _baseUrl = 'http://127.0.0.1:8080';

  // 1. GET ALL PRODUCTS
  Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$_baseUrl/produtos'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      // Tenta decodificar o erro do backend se houver
      String error = 'Erro desconhecido';
      try {
        final errorJson = jsonDecode(response.body);
        error = errorJson['error'] ?? 'Falha ao buscar produtos';
      } catch (_) {}
      throw Exception('Falha ao carregar produtos (Status ${response.statusCode}): $error');
    }
  }

  // 2. GET PRODUCT BY BARCODE (Usado pelo ProductFormScreen e SalesScreen)
  Future<Product?> getProductByBarcode(String barcode) async {
    // A API Go suporta ?barcode=...
    final response = await http.get(Uri.parse('$_baseUrl/produtos?barcode=$barcode'));

    if (response.statusCode == 200) {
      // Se for encontrado, a API Go retorna um *único* objeto (ou lista com 1)
      final dynamic data = jsonDecode(response.body);
      
      // Se a resposta for uma lista com um item:
      if (data is List && data.isNotEmpty) {
          return Product.fromJson(data[0]);
      } 
      // Se a resposta for um único objeto:
      if (data is Map<String, dynamic>) {
          // A API Go retorna um mapa, mas se for erro 404, ela retorna uma string
          if (data.containsKey('error')) {
            return null;
          }
          return Product.fromJson(data);
      }
      
    } else if (response.statusCode == 404) {
      // Produto não encontrado (Retorna null para o Form poder cadastrar)
      return null;
    }
    
    // Retorno padrão em caso de erro de servidor (e.g., 500)
    throw Exception('Erro ao buscar produto por código: Status ${response.statusCode}');
  }


  // 3. CREATE PRODUCT
  Future<void> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/produtos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode != 201) { // 201 é StatusCreated no Go
      String error = response.body;
      try {
        final errorJson = jsonDecode(response.body);
        error = errorJson['error'] ?? error;
      } catch (_) {}
      throw Exception('Falha ao criar produto: $error');
    }
  }

  // 4. UPDATE PRODUCT
  Future<void> updateProduct(Product product) async {
    final response = await http.put(
      // A rota PUT no backend Go é /produtos/{id}
      Uri.parse('$_baseUrl/produtos/${product.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode != 200) {
      String error = response.body;
      try {
        final errorJson = jsonDecode(response.body);
        error = errorJson['error'] ?? error;
      } catch (_) {}
      throw Exception('Falha ao atualizar produto: $error');
    }
  }

  // TODO: Implementar lógica de StockMovement no futuro
}