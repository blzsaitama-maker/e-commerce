import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import para LogicalKeyboardKey e SystemChrome
import 'package:intl/intl.dart'; 
import '../../../app/core/theme/app_colors.dart';
import '../../../app/data/models/product.dart';
import '../../../app/data/services/api_service.dart';

// Modelo simples para registro de venda (Histórico Local)
class SaleRecord {
  final int id;
  final DateTime date;
  final double total;
  final List<Map<String, dynamic>> items;

  SaleRecord({
    required this.id,
    required this.date,
    required this.total,
    required this.items,
  });
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // Serviços
  final ApiService _apiService = ApiService();

  // Controle de Foco e Texto
  final FocusNode _barcodeFocusNode = FocusNode();
  final FocusNode _nameSearchFocusNode = FocusNode(); 
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameSearchController = TextEditingController(); 
  
  // Timer para o Debounce (Auto-submit)
  Timer? _debounce;

  // Estado da Venda
  final List<Map<String, dynamic>> _cart = [];
  final List<SaleRecord> _salesHistory = []; 
  
  // Estado de Dados
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _currentQuantity = 1;

  @override
  void initState() {
    super.initState();
    // Ativa modo Fullscreen (Imersivo) ao entrar na tela
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _fetchProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestBarcodeFocus();
    });
  }

  // Busca os produtos reais do banco de dados
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _apiService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar produtos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Restaura as barras do sistema ao sair da tela
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    _debounce?.cancel();
    _barcodeFocusNode.dispose();
    _nameSearchFocusNode.dispose();
    _barcodeController.dispose();
    _nameSearchController.dispose();
    super.dispose();
  }

  void _requestBarcodeFocus() {
    if (mounted && !_nameSearchFocusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_barcodeFocusNode);
    }
  }

  // --- Lógica de Input com Debounce (Auto-Submit) ---

  void _onBarcodeChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (value.trim().isEmpty) return;

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _handleBarcodeSubmission(value);
    });
  }

  void _handleBarcodeSubmission(String value) {
    if (value.trim().isEmpty) {
      _requestBarcodeFocus();
      return;
    }

    String input = value.trim();

    if (input.contains('*')) {
      final parts = input.split('*');
      String qtyPart = parts.first.isNotEmpty ? parts.first : parts.last;
      String? productPart = parts.length > 1 && parts.last.isNotEmpty && parts.first.isNotEmpty 
          ? parts.last : null;

      final int? newQty = int.tryParse(qtyPart);
      
      if (newQty != null && newQty > 0) {
        setState(() => _currentQuantity = newQty);
        
        if (productPart != null) {
          _processProductAdd(productPart);
        } else {
          _barcodeController.clear();
          _requestBarcodeFocus();
        }
        return; 
      }
    }

    _processProductAdd(input);
  }

  void _processProductAdd(String term) {
    term = term.trim().toLowerCase();
    if (_products.isEmpty) return;

    final Product dummy = Product(id: -1, name: '', priceBuy: 0, priceSell: 0, stock: 0, category: '', manufacturingDate: DateTime.now(), expiryDate: DateTime.now());

    final Product foundProduct = _products.firstWhere(
      (p) => (p.barcode?.toLowerCase() == term) || (p.id.toString() == term),
      orElse: () => dummy,
    );

    if (foundProduct.id != -1) {
      _addToCart(foundProduct, qty: _currentQuantity);
      _resetInputState();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produto com código "$term" não encontrado.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      _barcodeController.selection = TextSelection(baseOffset: 0, extentOffset: _barcodeController.text.length);
    }
  }

  void _addToCart(Product product, {int qty = 1}) {
    setState(() {
      final index = _cart.indexWhere((item) => (item['product'] as Product).id == product.id);
      if (index >= 0) {
        _cart[index]['quantity'] = (_cart[index]['quantity'] as int) + qty;
      } else {
        _cart.add({'product': product, 'quantity': qty});
      }
    });
  }

  void _resetInputState() {
    setState(() => _currentQuantity = 1);
    _barcodeController.clear();
    _requestBarcodeFocus();
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _cancelSale() {
    setState(() {
      _cart.clear();
      _currentQuantity = 1;
    });
    _requestBarcodeFocus();
  }

  void _finishSale() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carrinho vazio! Adicione produtos.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final newSale = SaleRecord(
      id: _salesHistory.length + 1,
      date: DateTime.now(),
      total: _total,
      items: List.from(_cart),
    );

    setState(() {
      _salesHistory.insert(0, newSale);
      _cart.clear();
      _currentQuantity = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Venda Concluída!'), backgroundColor: Colors.green),
    );
    _requestBarcodeFocus();
  }

  void _reopenSale(SaleRecord sale) {
    setState(() {
      _cart.clear();
      for (var item in sale.items) {
        _cart.add({
          'product': item['product'], 
          'quantity': item['quantity']
        });
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Venda #${sale.id} carregada para o caixa!')),
    );
    _requestBarcodeFocus();
  }

  double get _total => _cart.fold(0.0, (sum, item) {
        final product = item['product'] as Product;
        final quantity = item['quantity'] as int;
        return sum + (product.priceSell * quantity);
      });

  // --- Widgets ---

  Widget _buildLeftPanel() {
    // AQUI: Garante que sempre mostra o histórico se não estiver carregando ou com erro
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 32, color: Colors.red),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _fetchProducts, child: const Text("Tentar Novamente"))
          ],
        ),
      );
    }

    return _buildSalesHistoryList();
  }

  Widget _buildSalesHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Vendas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
            IconButton(
              icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
              tooltip: "Atualizar",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _fetchProducts,
            ),
          ],
        ),
        const Divider(),
        _salesHistory.isEmpty 
          ? Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 30, color: Colors.grey[300]),
                    const SizedBox(height: 4),
                    Text("Vazio", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            )
          : Expanded(
              child: ListView.builder(
                itemCount: _salesHistory.length,
                itemBuilder: (context, index) {
                  final sale = _salesHistory[index];
                  final timeStr = "${sale.date.hour.toString().padLeft(2,'0')}:${sale.date.minute.toString().padLeft(2,'0')}";
                  
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () => _reopenSale(sale),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("#${sale.id}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "R\$ ${sale.total.toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcula 10% da largura da tela para usar como margem
    final double horizontalMargin = MediaQuery.of(context).size.width * 0.10;

    return Scaffold(
      backgroundColor: Colors.grey[100], 
      appBar: AppBar(
        title: const Text('PDV - Caixa'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: const [
                Icon(Icons.keyboard, size: 16, color: Colors.white70),
                SizedBox(width: 8),
                Text("'V' Finalizar | 'C' Cancelar | 'R' Voltar", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyV): () {
            if (!_nameSearchFocusNode.hasFocus) {
              _finishSale();
            }
          },
          const SingleActivator(LogicalKeyboardKey.keyC): () {
            if (!_nameSearchFocusNode.hasFocus) {
              _cancelSale();
            }
          },
          const SingleActivator(LogicalKeyboardKey.keyR): () {
            if (!_nameSearchFocusNode.hasFocus) {
              Navigator.of(context).pop();
            }
          },
        },
        child: Focus(
          autofocus: true,
          child: Row(
            children: [
              // LADO ESQUERDO: Histórico (Flex 2 = ~20%)
              Expanded(
                flex: 2, 
                child: Padding(
                  padding: const EdgeInsets.all(8.0), 
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8), 
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: _buildLeftPanel(),
                  ),
                ),
              ),
              
              // LADO DIREITO: Caixa Aberto (Flex 8 = ~80%)
              Expanded(
                flex: 8, 
                child: Padding(
                  padding: const EdgeInsets.all(8.0), 
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8), 
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                      ],
                    ),
                    // Sem margem extra, apenas padding do pai
                    child: Column(
                      children: [
                        // PARTE ROLÁVEL (Inputs + Lista)
                        Expanded( 
                          child: Column(
                            children: [
                              // --- Área de Inputs (Fixo no topo da lista) ---
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.indigo[50],
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // 1. Campo Autocomplete
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade400),
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Autocomplete<Product>(
                                            optionsBuilder: (TextEditingValue textEditingValue) {
                                              if (textEditingValue.text.isEmpty) {
                                                return const Iterable<Product>.empty();
                                              }
                                              return _products.where((Product option) {
                                                return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                              });
                                            },
                                            displayStringForOption: (Product option) => option.name,
                                            onSelected: (Product selection) {
                                              _addToCart(selection, qty: _currentQuantity);
                                              _resetInputState();
                                            },
                                            fieldViewBuilder: (context, fieldTextEditingController, fieldFocusNode, onFieldSubmitted) {
                                              return TextField(
                                                controller: fieldTextEditingController,
                                                focusNode: _nameSearchFocusNode, 
                                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                                                decoration: const InputDecoration(
                                                  hintText: 'Pesquisar produto por nome...',
                                                  hintStyle: TextStyle(color: Colors.black38),
                                                  prefixIcon: Icon(Icons.search, color: Colors.indigo),
                                                  border: InputBorder.none,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                ),
                                              );
                                            },
                                            optionsViewBuilder: (context, onSelected, options) {
                                              return Align(
                                                alignment: Alignment.topLeft,
                                                child: Material(
                                                  elevation: 4.0,
                                                  child: SizedBox(
                                                    width: constraints.maxWidth,
                                                    height: 200,
                                                    child: ListView.builder(
                                                      padding: EdgeInsets.zero,
                                                      shrinkWrap: true,
                                                      itemCount: options.length,
                                                      itemBuilder: (BuildContext context, int index) {
                                                        final Product option = options.elementAt(index);
                                                        return ListTile(
                                                          title: Text(option.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                          subtitle: Text('R\$ ${option.priceSell.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black87)),
                                                          trailing: Text('Est: ${option.stock}', style: const TextStyle(color: Colors.black54)),
                                                          onTap: () => onSelected(option),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        }
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 12),

                                    // 2. Linha Código de Barras + Quantidade
                                    Row(
                                      children: [
                                        // QTD
                                        Container(
                                          width: 80,
                                          height: 60,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.indigo.shade400, width: 1.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Text("QTD", style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
                                              Text(
                                                "$_currentQuantity",
                                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Código de Barras
                                        Expanded(
                                          child: TextField(
                                            controller: _barcodeController,
                                            focusNode: _barcodeFocusNode,
                                            autofocus: true,
                                            textInputAction: TextInputAction.next,
                                            style: const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w500),
                                            keyboardType: TextInputType.number, 
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                                            decoration: InputDecoration(
                                              hintText: 'Código ou Qtd*',
                                              hintStyle: const TextStyle(color: Colors.black38),
                                              labelText: 'Leitor de Código de Barras',
                                              labelStyle: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
                                              prefixIcon: const Icon(Icons.qr_code_scanner, color: Colors.black87),
                                              suffixIcon: IconButton(
                                                icon: const Icon(Icons.clear, color: Colors.black54),
                                                onPressed: () {
                                                  _barcodeController.clear();
                                                  _requestBarcodeFocus();
                                                },
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: Colors.black26),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: Colors.indigo, width: 2),
                                              ),
                                            ),
                                            onChanged: _onBarcodeChanged, 
                                            onSubmitted: _handleBarcodeSubmission, 
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // --- Lista de Itens (Expande para preencher o resto) ---
                              Expanded(
                                child: _cart.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
                                            const SizedBox(height: 16),
                                            Text('CAIXA LIVRE', style: TextStyle(color: Colors.grey[600], fontSize: 28, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 8),
                                            Text('Passe os produtos ou digite o código.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                          ],
                                        ),
                                      )
                                    : Padding(
                                        padding: EdgeInsets.symmetric(horizontal: horizontalMargin), // AQUI: Margem de 10% nas laterais da lista
                                        child: ListView.separated(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          itemCount: _cart.length,
                                          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
                                          itemBuilder: (context, index) {
                                            final invertedIndex = _cart.length - 1 - index;
                                            final item = _cart[invertedIndex];
                                            
                                            final p = item['product'] as Product;
                                            final qty = item['quantity'] as int;
                                            final isLastAdded = index == 0; 
                                            
                                            return Container(
                                              color: isLastAdded ? Colors.green.withOpacity(0.1) : null,
                                              child: ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                // LIXEIRA À ESQUERDA
                                                leading: SizedBox(
                                                  width: 50,
                                                  height: 50,
                                                  child: ElevatedButton(
                                                    onPressed: () => _removeFromCart(invertedIndex),
                                                    style: ElevatedButton.styleFrom(
                                                      padding: EdgeInsets.zero,
                                                      backgroundColor: Colors.red.shade50,
                                                      foregroundColor: Colors.red,
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                        side: BorderSide(color: Colors.red.shade200),
                                                      ),
                                                    ),
                                                    child: const Icon(Icons.delete_outline, size: 28),
                                                  ),
                                                ),
                                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
                                                subtitle: Row(
                                                  children: [
                                                    // QUANTIDADE NO SUBTÍTULO
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.indigo.shade100,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text("${qty}x", style: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.bold, fontSize: 14)),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text('${p.barcode ?? "Sem Cód."}', style: const TextStyle(color: Colors.black54, fontSize: 14)),
                                                  ],
                                                ),
                                                trailing: SizedBox( // AQUI: Usando SizedBox para controlar largura e evitar overflow
                                                  width: 250, // Largura fixa ou proporcional
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end, 
                                                    crossAxisAlignment: CrossAxisAlignment.center, 
                                                    children: [
                                                      // VALOR UNITÁRIO (ESQUERDA - Menor)
                                                      Text('un. R\$ ${p.priceSell.toStringAsFixed(2)}', 
                                                        style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
                                                      
                                                      const SizedBox(width: 24), // Espaçamento maior
                                                      
                                                      // VALOR TOTAL DO ITEM (DIREITA - Maior e mais destacado)
                                                      Expanded(
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          alignment: Alignment.centerRight,
                                                          child: Text('R\$ ${(p.priceSell * qty).toStringAsFixed(2)}', 
                                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: Colors.green)), // Fonte aumentada
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),

                        // Rodapé Totais (Fixo na parte inferior)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, -6)),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // BOTÃO CANCELAR
                              SizedBox(
                                width: 150, 
                                height: 100, 
                                child: OutlinedButton(
                                  onPressed: _cart.isEmpty ? null : _cancelSale,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red, width: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.close, color: Colors.red, size: 36),
                                      SizedBox(height: 8),
                                      Text('CANCELAR\n(C)', textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 24),

                              // TOTAL (MEIO - Expansível com FittedBox para fonte proporcional)
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // FittedBox aqui também garante que o título não quebre se a tela for minúscula
                                    const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('TOTAL A PAGAR', style: TextStyle(fontSize: 24, color: Colors.black54, fontWeight: FontWeight.bold))
                                    ),
                                    // AQUI: FittedBox para o valor gigante se adaptar proporcionalmente
                                    FittedBox( 
                                      fit: BoxFit.scaleDown,
                                      child: Text('R\$ ${_total.toStringAsFixed(2)}', 
                                        style: const TextStyle(fontSize: 90, fontWeight: FontWeight.w900, color: Colors.green, height: 1.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 24),

                              // BOTÃO FINALIZAR
                              SizedBox(
                                width: 150, 
                                height: 100, 
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 4,
                                  ),
                                  onPressed: _finishSale,
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check, color: Colors.white, size: 36),
                                      SizedBox(height: 8),
                                      Text('FINALIZAR\n(V)', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}