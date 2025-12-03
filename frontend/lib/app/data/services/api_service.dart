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
      // O backend pode retornar null em vez de [] para uma lista vazia
      if (body == null) {
        return [];
      }
      return (body as List).map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao carregar produtos');
    }
  }

  // 2. GET: Listar Vencendo (Sua rota especial)
  Future<List<Product>> getExpiringProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/produtos/vencendo'));

    if (response.statusCode == 200) {
       final body = jsonDecode(response.body);
      if (body == null) {
        return [];
      }
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
      body: jsonEncode(product.toJson()), // Aqui usamos o toJson que criamos
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao criar produto: ${response.body}');
    }
  }
}
