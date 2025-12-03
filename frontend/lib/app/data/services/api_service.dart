import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  // ⚠️ USE ESTE PARA LINUX DESKTOP:
  static const String baseUrl = 'http://localhost:8080';

  // 1. GET: Listar todos
  Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/produtos'));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body == null) return [];
      return (body as List).map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar produtos');
    }
  }

  // 2. GET: Listar Vencendo
  Future<List<Product>> getExpiringProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/produtos/vencendo'));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body == null) return [];
      return (body as List).map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar alertas');
    }
  }

  // 3. POST: Criar Produto
  Future<void> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$baseUrl/produtos'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao criar produto: ${response.body}');
    }
  }

  // 4. PUT: Atualizar Produto Existente
  Future<void> updateProduct(Product product) async {
    // Assumindo que sua API aceite PUT em /produtos/{id}
    if (product.id == null) return;

    final response = await http.put(
      Uri.parse('$baseUrl/produtos/${product.id}'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao atualizar produto: ${response.body}');
    }
  }

  // 5. GET: Buscar por Código de Barras
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      // Ajuste a query string conforme seu backend (ex: ?barcode=... ou filtro manual)
      final response = await http.get(
        Uri.parse('$baseUrl/produtos?barcode=$barcode'),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body == null || (body is List && body.isEmpty)) {
          return null;
        }

        // Pega o primeiro item se for uma lista, ou o próprio corpo se for um mapa.
        final Map<String, dynamic> productJson = body is List
            ? body.first
            : body;

        return Product.fromJson(productJson);
      }
    } catch (e) {
      print("Erro ao buscar produto: $e");
    }
    return null;
  }
}
