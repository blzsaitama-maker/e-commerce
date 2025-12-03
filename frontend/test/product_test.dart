import 'package:test/test.dart';
import 'package:frontend/app/data/models/product.dart';

/// Retorna a query SQL para criar a tabela de produtos.
String createProductTableQuery() {
  return '''CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        preco_buy REAL NOT NULL,
        preco_sell REAL NOT NULL,
        stock INTEGER NOT NULL,
        category TEXT,
        manufacturing_date TEXT,
        expiry_date TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        barcode TEXT NOT NULL,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );''';
}

void main() {
  // Grupo de testes para a criação da tabela de produtos.
  group('createProductTableQuery', () {
    test('deve retornar a string SQL correta para criar a tabela', () {
      const expectedSQL = '''CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        preco_buy REAL NOT NULL,
        preco_sell REAL NOT NULL,
        stock INTEGER NOT NULL,
        category TEXT,
        manufacturing_date TEXT,
        expiry_date TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        barcode TEXT NOT NULL,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );''';

      final actualSQL = createProductTableQuery();
      expect(actualSQL, expectedSQL);
    });
  });

  // Grupo de testes para a lógica de validade
  group('Product Validity (Regra dos 80%)', () {
    // CASO 1: Produto muito novo (0% passado)
    test('Produto NOVO não deve estar perto de vencer', () {
      final now = DateTime.now();
      final pNew = Product(
        name: 'Leite Fresco',
        manufacturingDate: now,
        priceBuy: 2.0,
        priceSell: 4.0,
        stock: 10,
        category: 'Laticínios',
        // Vence em 100 horas a partir de agora
        expiryDate: now.add(Duration(hours: 100)),
      );

      expect(
        pNew.isNearExpiry(referenceDate: now),
        isFalse,
        reason: 'Produto acabou de ser fabricado',
      );
    });

    // CASO 2: Limite Seguro (79% passado)
    // Vida total: 100h. Alerta aos 80h. Passaram-se 79h.
    test(
      'Produto com 79% da vida passada NÃO deve alertar (Limite Inferior)',
      () {
        final now = DateTime.now();
        final pSafe = Product(
          name: 'Produto Quase no Limite',
          // Fabricado há 79 horas
          priceBuy: 2.0,
          priceSell: 4.0,
          stock: 10,
          category: 'Geral',
          manufacturingDate: now.subtract(Duration(hours: 79)),
          // Vence em 21 horas (Total 100h). O alerta dispara quando faltarem 20h.
          expiryDate: now.add(Duration(hours: 21)),
        );

        expect(
          pSafe.isNearExpiry(referenceDate: now),
          isFalse,
          reason: 'Ainda não atingiu 80% da vida útil',
        );
      },
    );

    // CASO 3: Limite de Alerta (81% passado)
    // Vida total: 100h. Alerta aos 80h. Passaram-se 81h.
    test('Produto com 81% da vida passada DEVE alertar (Limite Superior)', () {
      final now = DateTime.now();
      final pAlert = Product(
        name: 'Produto Recém Alertado',
        // Fabricado há 81 horas
        priceBuy: 2.0,
        priceSell: 4.0,
        stock: 10,
        category: 'Geral',
        manufacturingDate: now.subtract(Duration(hours: 81)),
        // Vence em 19 horas (Total 100h). O alerta dispara quando faltarem 20h.
        expiryDate: now.add(Duration(hours: 19)),
      );

      expect(
        pAlert.isNearExpiry(referenceDate: now),
        isTrue,
        reason: 'Passou um pouco dos 80% da vida útil',
      );
    });

    // CASO 4: Produto Velho (90% passado)
    test('Produto VELHO (passou 90% da vida) deve alertar', () {
      final now = DateTime.now();
      final pOld = Product(
        name: 'Queijo Antigo',
        priceBuy: 2.0,
        priceSell: 4.0,
        stock: 10,
        category: 'Laticínios',
        manufacturingDate: now.subtract(Duration(hours: 90)),
        expiryDate: now.add(Duration(hours: 10)),
      );

      expect(
        pOld.isNearExpiry(referenceDate: now),
        isTrue,
        reason: 'Já passou de 80% da vida útil',
      );
    });

    // CASO 5: Produto Vencido
    test('Produto VENCIDO deve alertar', () {
      final now = DateTime.now();
      final pExpired = Product(
        name: 'Iogurte Vencido',
        priceBuy: 2.0,
        priceSell: 4.0,
        stock: 10,
        category: 'Laticínios',
        manufacturingDate: now.subtract(Duration(hours: 200)),
        expiryDate: now.subtract(Duration(hours: 1)),
      );

      expect(
        pExpired.isNearExpiry(referenceDate: now),
        isTrue,
        reason: 'Produto já venceu',
      );
    });
  });
}
