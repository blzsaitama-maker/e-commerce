class Product {
  final int? id;
  final String name;
  final double priceBuy;
  final double priceSell;
  final int stock;
  final String category;
  final DateTime manufacturingDate;
  final DateTime expiryDate;
  final String? barcode; // New field

  Product({
    this.id,
    required this.name,
    required this.priceBuy,
    required this.priceSell,
    required this.stock,
    required this.category,
    required this.manufacturingDate,
    required this.expiryDate,
    this.barcode, // New field in constructor
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['ID'],
      name: json['name'] ?? '',
      priceBuy: (json['price_buy'] as num?)?.toDouble() ?? 0.0,
      priceSell: (json['price_sell'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] ?? 0,
      category: json['category'] ?? '',
      manufacturingDate: json['manufacturing_date'] != null
          ? DateTime.parse(json['manufacturing_date'])
          : DateTime.now(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : DateTime.now(),
      barcode: json['barcode'], // Parse barcode
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price_buy': priceBuy,
      'price_sell': priceSell,
      'stock': stock,
      'category': category,
      'manufacturing_date': manufacturingDate.toUtc().toIso8601String(),
      'expiry_date': expiryDate.toUtc().toIso8601String(),
      'barcode': barcode, // Include barcode in JSON
    };
  }

  /// Verifica se o produto já passou de 80% da vida útil em relação a um [referenceDate].
  /// Se [referenceDate] for nulo, usa o tempo atual.
  bool isNearExpiry({DateTime? referenceDate}) {
    // 1. Calcula a vida total do produto
    final totalLife = expiryDate.difference(manufacturingDate);

    // Se a vida total for zero ou negativa (datas inválidas), considere perto de vencer.
    if (totalLife.inSeconds <= 0) return true;

    // 2. Calcula o tempo de alerta (quando 80% da vida útil tiver passado, restando 20%)
    final alertDuration = totalLife * 0.2;

    // 3. Define a data de disparo do alerta (Data de Vencimento - 20% da vida útil)
    final triggerDate = expiryDate.subtract(alertDuration);

    // 4. Verifica se "Agora" já passou dessa data de gatilho
    final now = referenceDate ?? DateTime.now();
    return now.isAfter(triggerDate);
  }
}
