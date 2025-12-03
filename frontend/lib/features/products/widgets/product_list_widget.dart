import 'package:flutter/material.dart';
import '../../../app/data/models/product.dart';
import '../../../app/data/services/api_service.dart';

class ProductListWidget extends StatefulWidget {
  const ProductListWidget({super.key});

  @override
  State<ProductListWidget> createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<ProductListWidget> {
  final ApiService apiService = ApiService();
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = apiService.getProducts();
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = apiService.getProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhum produto encontrado.'));
        }

        final products = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async => _refreshProducts(),
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text(product.category),
                trailing: Text('R\$ ${product.priceSell.toStringAsFixed(2)}'),
              );
            },
          ),
        );
      },
    );
  }
}
