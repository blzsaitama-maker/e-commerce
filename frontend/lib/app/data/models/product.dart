import 'dart:convert';

class Product {
  final int id;
  final String name;
  final double priceBuy;
  final double priceSell;
  final int stock;
  final int minStock;
  final String category; // Nome da categoria para exibir na tela
  final int categoryId;  // ID para enviar pro backend
  final String barcode;
  final DateTime? manufacturingDate;
  final DateTime? expiryDate;

  Product({
    this.id = 0,
    required this.name,
    required this.priceBuy,
    required this.priceSell,
    required this.stock,
    this.minStock = 5,
    this.category = 'Geral',
    this.categoryId = 1,
    this.barcode = '',
    this.manufacturingDate,
    this.expiryDate,
  });

  // --- O PULO DO GATO PARA NÃO CRASHAR ---
  factory Product.fromJson(Map<String, dynamic> json) {
    // 1. Extração Segura da Categoria (Suporta Objeto ou String)
    String catName = 'Geral';
    int catId = 1;

    if (json['category'] != null) {
      if (json['category'] is Map) {
        // Se vier do Backend Novo (Objeto)
        catName = json['category']['name'] ?? 'Geral';
        catId = json['category']['id'] ?? 1;
      } else if (json['category'] is String) {
        // Se vier do Backend Antigo ou gambiarra (String)
        catName = json['category'];
      }
    }

    // 2. Extração do ID da Categoria (se vier solto)
    if (json['category_id'] != null) {
      catId = json['category_id'];
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Sem Nome',
      // Conversão segura para double (mesmo que venha int do JSON)
      priceBuy: (json['price_buy'] ?? 0).toDouble(),
      priceSell: (json['price_sell'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      minStock: json['min_stock'] ?? 5,
      category: catName,
      categoryId: catId,
      barcode: json['barcode'] ?? '',
      manufacturingDate: json['manufacturing_date'] != null
          ? DateTime.tryParse(json['manufacturing_date'])
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price_buy': priceBuy,
      'price_sell': priceSell,
      'stock': stock,
      'min_stock': minStock,
      'category_id': categoryId, // Backend agora espera category_id, não category name
      'barcode': barcode,
      'manufacturing_date': manufacturingDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }

  // Helper para saber se está vencendo (Lógica espelhada do Backend)
  bool get isNearExpiry {
    if (expiryDate == null || manufacturingDate == null) return false;
    final totalLife = expiryDate!.difference(manufacturingDate!);
    final alertDuration = Duration(days: (totalLife.inDays / 5).round());
    final triggerDate = expiryDate!.subtract(alertDuration);
    return DateTime.now().isAfter(triggerDate);
  }
}