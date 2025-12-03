import 'package:frontend/app/data/models/category.dart'; // Import necessário

class Product {
  // Tornamos o ID NULO para permitir a criação de um novo produto (sem ID inicial)
  final int? id; 
  final String name;
  final String? barcode;
  final double priceBuy;
  final double priceSell;
  final int stock;
  final int minStock;
  final int categoryId;
  final Category? category; // Objeto categoria opcional
  final DateTime? manufacturingDate;
  final DateTime? expiryDate;

  Product({
    this.id, // Não tem mais valor padrão 0, é nulo para novos produtos
    required this.name,
    this.barcode = '',
    required this.priceBuy,
    required this.priceSell,
    required this.stock,
    this.minStock = 5,
    this.categoryId = 1, // Padrão 'Geral'
    this.category,
    this.manufacturingDate,
    this.expiryDate,
  });

  // --- FACTORY CONSTRUCTOR (fromJson) ---
  factory Product.fromJson(Map<String, dynamic> json) {
    // 1. Extração Segura da Categoria e ID
    Category? catObject;
    int catId = json['category_id'] ?? 1; // Prioriza o ID solto
    
    if (json['category'] != null) {
      if (json['category'] is Map) {
        // Se vier do Backend Novo (Objeto)
        catObject = Category.fromJson(json['category']);
        catId = catObject.id; // Atualiza o ID caso só venha no objeto
      } 
    }

    // 2. Constrói o Produto
    return Product(
      id: json['id'],
      name: json['name'] ?? 'Sem Nome',
      barcode: json['barcode'] ?? '',
      // Conversão segura para double, tratando 'num' (int/double)
      priceBuy: (json['price_buy'] as num?)?.toDouble() ?? 0.0,
      priceSell: (json['price_sell'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] ?? 0,
      minStock: json['min_stock'] ?? 5,
      categoryId: catId,
      category: catObject,
      manufacturingDate: json['manufacturing_date'] != null
          ? DateTime.tryParse(json['manufacturing_date'])
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'])
          : null,
    );
  }

  // --- SERIALIZAÇÃO (toJson) ---
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'name': name,
      'barcode': barcode,
      'price_buy': priceBuy,
      'price_sell': priceSell,
      'stock': stock,
      'min_stock': minStock,
      'category_id': categoryId, // Backend espera o ID
      'manufacturing_date': manufacturingDate?.toUtc().toIso8601String(),
      'expiry_date': expiryDate?.toUtc().toIso8601String(),
    };
    // IMPORTANTE: Remove chaves com valores nulos antes de enviar para o backend.
    // Isso evita problemas com campos 'omitempty' no Go.
    json.removeWhere((key, value) => value == null);
    return json;
  }

  // Helper para saber se está vencendo
  bool get isNearExpiry {
    if (expiryDate == null || manufacturingDate == null) return false;
    final totalLife = expiryDate!.difference(manufacturingDate!);
    final alertDuration = Duration(days: (totalLife.inDays / 5).round());
    final triggerDate = expiryDate!.subtract(alertDuration);
    return DateTime.now().isAfter(triggerDate);
  }
}