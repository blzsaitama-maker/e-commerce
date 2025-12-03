// Adicione este import no topo do arquivo se não tiver
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/app/data/models/product.dart';
import 'package:frontend/app/data/services/api_service.dart';
import 'package:intl/intl.dart';

// --- WIDGET STATEFUL (CLASSE PRINCIPAL) ---
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

// --- FORMATAÇÃO AUXILIAR (COPIE JUNTO) ---
class BarcodeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    var newText = '';
    for (var i = 0; i < text.length; i++) {
      newText += text[i];
      // Adiciona um hífen a cada 3 caracteres, mas não no final
      if ((i + 1) % 3 == 0 && i != text.length - 1) {
        newText += '-';
      }
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // O texto vem apenas com dígitos por causa do FilteringTextInputFormatter
    String newText = newValue.text;

    if (newText.isEmpty) {
      return newValue.copyWith(text: '0.00');
    }

    // Remove zeros à esquerda, ex: 0050 -> 50
    newText = int.parse(newText).toString();

    // Adiciona zeros à esquerda para ter pelo menos 3 dígitos (para centavos)
    if (newText.length < 3) {
      newText = newText.padLeft(3, '0');
    }

    // Insere o ponto decimal
    newText =
        '${newText.substring(0, newText.length - 2)}.${newText.substring(newText.length - 2)}';

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();

  // Variáveis para controle de busca automática
  Timer? _debounce;
  int?
  _editingProductId; // Se for null, é cadastro novo. Se tiver ID, é atualização.

  // --- Controllers ---
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();

  final _priceBuyController = TextEditingController(text: '0.00');
  final _priceSellController = TextEditingController(text: '0.00');

  final _stockController = TextEditingController();
  final _marginController = TextEditingController();
  final _deptController = TextEditingController();
  final _minStockController = TextEditingController();
  final _ipiController = TextEditingController(text: '0.00');
  final _icmsController = TextEditingController(text: '18.00');
  final _ncmController = TextEditingController();

  String? _selectedSupplier = 'Nenhum';
  String? _selectedUnit = 'UN';
  final List<String> _suppliers = [
    'Nenhum',
    'Fornecedor A',
    'Fornecedor B',
    'Fornecedor C',
  ];
  final List<String> _units = ['UN', 'KG', 'CX', 'PCT', 'LITRO'];

  DateTime _manufacturingDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    // Adiciona o ouvinte para detectar quando o usuário digita no código de barras
    _barcodeController.addListener(_onBarcodeChanged);
  }

  @override
  void dispose() {
    _barcodeController.removeListener(_onBarcodeChanged);
    _debounce?.cancel(); // Cancela o timer se sair da tela
    _nameController.dispose();
    _barcodeController.dispose();
    _priceBuyController.dispose();
    _priceSellController.dispose();
    _stockController.dispose();
    _marginController.dispose();
    _deptController.dispose();
    _minStockController.dispose();
    _ipiController.dispose();
    _icmsController.dispose();
    _ncmController.dispose();
    super.dispose();
  }

  // --- Lógica de Busca Automática (Debounce) ---
  void _onBarcodeChanged() {
    // Se o timer já estiver rodando, cancela (o usuário ainda está digitando)
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Cria um novo timer de 1 segundo (ajuste conforme necessário)
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      final barcode = _barcodeController.text.replaceAll('-', '').trim();
      if (barcode.isNotEmpty && barcode.length > 2) {
        _checkBarcodeExists(barcode);
      }
    });
  }

  Future<void> _checkBarcodeExists(String barcode) async {
    // Evita buscar se for o mesmo que já está carregado
    // if (_editingProductId != null) return;

    try {
      final product = await apiService.getProductByBarcode(barcode);

      if (!mounted) return;

      if (product != null) {
        // --- CENÁRIO: PRODUTO JÁ EXISTE ---
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Produto encontrado! Carregando dados para edição...',
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );

        setState(() {
          _editingProductId = product.id; // Salva o ID para usar no UPDATE

          _nameController.text = product.name;
          // Formata os preços para o padrão do controller (com ponto e 2 casas)
          _priceBuyController.text = product.priceBuy.toStringAsFixed(2);
          _priceSellController.text = product.priceSell.toStringAsFixed(2);
          _stockController.text = product.stock.toString();

          // Tenta selecionar fornecedor e unidade se existirem na lista
          if (_suppliers.contains(product.category)) {
            _selectedSupplier = product.category;
          }

          // Preenche datas
          // CORREÇÃO: Se a data do produto for nula, usamos a data atual como padrão.
          _manufacturingDate = product.manufacturingDate ?? DateTime.now();
          _expiryDate =
              product.expiryDate ??
              DateTime.now().add(const Duration(days: 30));

          // Recalcula margem visualmente
          _calculateMargin();
        });
      } else {
        // --- CENÁRIO: PRODUTO NÃO EXISTE (Novo Cadastro) ---
        // Se a gente já estava editando algo e digitou um código novo, limpa o ID
        if (_editingProductId != null) {
          setState(() {
            _editingProductId = null; // Volta a ser um INSERT
            // Opcional: Limpar os outros campos se quiser forçar redigitação
            // _nameController.clear();
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código novo. Preencha os dados para cadastrar.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Erro na busca automática: $e");
    }
  }

  // --- Lógica de Cálculo ---
  void _calculateSellPrice() {
    double cost = double.tryParse(_priceBuyController.text) ?? 0.0;
    double margin = double.tryParse(_marginController.text) ?? 0.0;
    double ipi = double.tryParse(_ipiController.text) ?? 0.0;

    if (cost > 0) {
      double costWithTax = cost + (cost * (ipi / 100));
      double sellPrice = costWithTax + (costWithTax * (margin / 100));
      _priceSellController.text = sellPrice.toStringAsFixed(2);
    }
  }

  void _calculateMargin() {
    double cost = double.tryParse(_priceBuyController.text) ?? 0.0;
    double sell = double.tryParse(_priceSellController.text) ?? 0.0;
    if (cost > 0 && sell > 0) {
      double margin = ((sell - cost) / cost) * 100;
      _marginController.text = margin.toStringAsFixed(2);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        id: _editingProductId ?? 0, // IMPORTANTE: Passa o ID se for edição
        name: _nameController.text,
        priceBuy: double.tryParse(_priceBuyController.text) ?? 0.0,
        priceSell: double.tryParse(_priceSellController.text) ?? 0.0,
        stock: int.tryParse(_stockController.text) ?? 0,
        manufacturingDate: _manufacturingDate,
        expiryDate: _expiryDate,
        barcode: _barcodeController.text.replaceAll('-', ''),
      );

      try {
        if (_editingProductId == null) {
          // --- CRIAR NOVO ---
          await apiService.createProduct(newProduct);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Produto CADASTRADO com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // --- ATUALIZAR EXISTENTE ---
          await apiService.updateProduct(newProduct);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Produto ATUALIZADO com sucesso!'),
                backgroundColor: Colors.blueAccent,
              ),
            );
          }
        }
        _clearForm();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _clearForm() {
    // Cancela debounce pendente para evitar trigger fantasma
    _debounce?.cancel();

    _formKey.currentState!.reset();
    _nameController.clear();
    _barcodeController
        .clear(); // Isso vai disparar o listener, mas como está vazio, o debounce ignora

    _priceBuyController.text = '0.00';
    _priceSellController.text = '0.00';
    _stockController.clear();
    _marginController.clear();

    setState(() {
      _editingProductId = null; // Reseta para modo de criação
      _selectedSupplier = 'Nenhum';
      _manufacturingDate = DateTime.now();
    });

    // Pequeno delay para focar no campo de código de barras novamente
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(
        context,
      ).requestFocus(FocusNode()); // Opcional: focar onde preferir
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // === MODIFICAÇÃO 1: Fundo Cinza Claro ===
      backgroundColor: Colors.grey[50], 
      body: Column(
        children: [
          // Barra de Título
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.app_registration, size: 20),
                const SizedBox(width: 10),
                // LÓGICA VISUAL: Mostra se está Editando ou Criando
                Text(
                  _editingProductId == null
                      ? "CADASTRO DE MERCADORIAS - F3"
                      : "EDITANDO PRODUTO (ID: $_editingProductId)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _editingProductId == null
                        ? Colors.black
                        : Colors.blue[900],
                  ),
                ),
                const Spacer(),
                Text(
                  "V 1.0",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // === SEÇÃO 1: CABEÇALHO ===
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // CÓDIGO DE BARRAS (Flex 2)
                                  Expanded(
                                    flex: 2,
                                    child: _buildTextField(
                                      controller: _barcodeController,
                                      label: 'Cód. Barras',
                                      isNumber: true,
                                      isBold: true,
                                      autofocus: true,
                                      textColor: Colors.blue[900],
                                      formatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        BarcodeTextInputFormatter(),
                                      ],
                                      // Mantendo amarelo claro para destaque
                                      color: Colors.yellow[100], 
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // NCM (Flex 1)
                                  Expanded(
                                    flex: 1,
                                    child: _buildTextField(
                                      controller: _ncmController,
                                      label: 'NCM (Fiscal)',
                                      isNumber: true,
                                      isBold: true,
                                      textColor: Colors.blue[900],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // UNIDADE (Flex 1)
                                  Expanded(
                                    flex: 1,
                                    child: _buildDropdown(
                                      label: 'Unid.',
                                      value: _selectedUnit,
                                      items: _units,
                                      onChanged: (v) =>
                                          setState(() => _selectedUnit = v),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // NOME
                              _buildTextField(
                                controller: _nameController,
                                label: 'NOME',
                                isBold: true,
                                textColor: Colors.blue[900],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildDropdown(
                                      label: 'Fornecedor',
                                      value: _selectedSupplier,
                                      items: _suppliers,
                                      onChanged: (v) =>
                                          setState(() => _selectedSupplier = v),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: _buildTextField(
                                      controller: _deptController,
                                      label: 'Seção / Depto',
                                      isBold: true,
                                      textColor: Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Placeholder Foto
                        Column(
                          children: [
                            const Text(
                              "FOTO",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 100,
                              height: 145,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                color: Colors.black12,
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                  Text(
                                    "Sem Imagem",
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // === SEÇÃO 2: PREÇOS ===
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              // === MODIFICAÇÃO 3: Fundo do Painel de Custos
                              color: Colors.white.withOpacity(0.8), 
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader("CUSTOS & IMPOSTOS"),
                                Row(
                                  children: [
                                    // PREÇO COMPRA
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _priceBuyController,
                                        label: 'Preço Compra R\$',
                                        isNumber: true,
                                        isBold: true,
                                        textColor: Colors.red,
                                        formatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          MoneyInputFormatter(),
                                        ],
                                        onChanged: (_) => _calculateSellPrice(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _ipiController,
                                        label: 'I.P.I %',
                                        isNumber: true,
                                        isBold: true,
                                        textColor: Colors.blue[900],
                                        onChanged: (_) => _calculateSellPrice(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _icmsController,
                                        label: 'ICMS Compra %',
                                        isNumber: true,
                                        isBold: true,
                                        textColor: Colors.blue[900],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: TextEditingController(
                                          text: '0.00',
                                        ),
                                        label: 'Frete %',
                                        isNumber: true,
                                        isBold: true,
                                        textColor: Colors.blue[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              // === MODIFICAÇÃO 3: Fundo do Painel de Preço Final
                              color: Colors.white.withOpacity(0.8), 
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader("PREÇO FINAL"),
                                // MARGEM
                                _buildTextField(
                                  controller: _marginController,
                                  label: 'Margem Lucro %',
                                  isNumber: true,
                                  isBold: true,
                                  textColor: Colors.green,
                                  onChanged: (_) => _calculateSellPrice(),
                                ),
                                const SizedBox(height: 12),
                                // PREÇO VENDA
                                _buildTextField(
                                  controller: _priceSellController,
                                  label: 'PREÇO VENDA R\$',
                                  isNumber: true,
                                  isBold: true,
                                  textColor: Colors.green,
                                  color: Colors.greenAccent.withOpacity(0.1),
                                  formatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    MoneyInputFormatter(),
                                  ],
                                  onChanged: (_) => _calculateMargin(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // === SEÇÃO 3: ESTOQUE ===
                    Row(
                      children: [
                        Expanded(
                          // ESTOQUE
                          child: _buildTextField(
                            controller: _stockController,
                            label: 'Estoque Atual',
                            isNumber: true,
                            icon: Icons.inventory,
                            isBold: true,
                            textColor: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            controller: _minStockController,
                            label: 'Estoque Mín.',
                            isNumber: true,
                            isBold: true,
                            textColor: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDatePicker(
                            context: context,
                            label: 'Data Validade',
                            date: _expiryDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _expiryDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null)
                                setState(() => _expiryDate = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // === RODAPÉ ===
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFooterButton(
                  Icons.search,
                  'Pesquisar (F2)',
                  Colors.blue,
                  () {},
                ),
                _buildFooterButton(
                  Icons.add,
                  'Novo (F3)',
                  Colors.orange,
                  _clearForm,
                ),
                _buildFooterButton(Icons.delete, 'Excluir', Colors.red, () {}),
                _buildFooterButton(
                  Icons.cancel,
                  'Cancelar',
                  Colors.grey,
                  _clearForm,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _editingProductId == null
                          ? Colors.green[700]
                          : Colors.blue[700], // COR MUDA SE FOR EDITAR
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    icon: Icon(
                      _editingProductId == null ? Icons.save : Icons.update,
                    ),
                    label: Text(
                      _editingProductId == null
                          ? 'SALVAR (F10)'
                          : 'ATUALIZAR (F10)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets Auxiliares ---

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: const InputDecoration(
              filled: true, // Adicionado para manter a consistência visual
              fillColor: Colors.white, // Fundo branco
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
            items: items
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool isNumber = false,
    bool isBold = false,
    bool autofocus = false,
    Color? color,
    Color? textColor,
    Function(String)? onChanged,
    List<TextInputFormatter>? formatters,
  }) {
    List<TextInputFormatter> appliedFormatters = formatters ?? [];
    if (appliedFormatters.isEmpty && isNumber) {
      appliedFormatters.add(
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: TextFormField(
            controller: controller,
            autofocus: autofocus,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            onChanged: onChanged,
            inputFormatters: appliedFormatters.isNotEmpty
                ? appliedFormatters
                : null,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 14 : 13,
              color: textColor,
            ),
            decoration: InputDecoration(
              // === MODIFICAÇÃO 2: Campos de Texto Fundo Branco ===
              filled: true,
              fillColor: color ?? Colors.white, // Usa 'color' se for passado (ex: amarelo), senão usa BRANCO
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.only(
                left: 8,
                right: 8,
                bottom: 8,
              ),
              prefixIcon: icon != null ? Icon(icon, size: 16) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              // Adicionado fundo branco aqui também para consistência
              color: Colors.white, 
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: const TextStyle(fontSize: 13),
                ),
                const Icon(Icons.calendar_month, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}