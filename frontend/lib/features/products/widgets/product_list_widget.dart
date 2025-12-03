import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/app/data/models/product.dart'; // Importe o modelo novo

class ProductListWidget extends StatefulWidget {
  const ProductListWidget({super.key});

  @override
  State<ProductListWidget> createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<ProductListWidget> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    try {
      // Ajuste a URL se necessário (localhost para Linux Desktop funciona)
      final response = await http.get(Uri.parse('http://localhost:8080/produtos'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Aqui o fromJson blindado vai evitar o crash
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Falha no servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _productsFuture = _fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          // 1. Estado de Carregamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Estado de Erro (Mostra na tela em vez de tela branca!)
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar produtos:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text("Tentar Novamente"),
                  )
                ],
              ),
            );
          }

          // 3. Estado Vazio
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nenhum produto cadastrado."));
          }

          // 4. Lista de Produtos (Sucesso)
          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: product.isNearExpiry ? Colors.red : Colors.green,
                    child: Icon(
                      product.isNearExpiry ? Icons.warning : Icons.check,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text("${product.category} • Estoque: ${product.stock}"),
                  trailing: Text(
                    "R\$ ${product.priceSell.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onTap: () {
                    // Navegar para detalhes/edição (implementar depois)
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}