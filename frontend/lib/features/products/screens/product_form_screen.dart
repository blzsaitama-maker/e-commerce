import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for TextInputFormatter
import '../../../app/data/models/product.dart';
import '../../../app/data/services/api_service.dart';

// Custom formatter for barcode
class BarcodeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('-', '');
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    var newText = '';
    for (int i = 0; i < text.length; i++) {
      newText += text[i];
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        newText += '-';
      }
    }
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController(); // New barcode controller
  final _priceBuyController = TextEditingController();
  final _priceSellController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedSupplier = 'Nenhum'; // Default supplier
  final List<String> _suppliers = ['Nenhum', 'Fornecedor A', 'Fornecedor B', 'Fornecedor C']; // Hardcoded suppliers

  DateTime _manufacturingDate = DateTime.now();
  DateTime _expiryDate = DateTime.now();

  final ApiService apiService = ApiService();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        name: _nameController.text,
        priceBuy: double.parse(_priceBuyController.text),
        priceSell: double.parse(_priceSellController.text),
        stock: int.parse(_stockController.text),
        category: _selectedSupplier!, // Use selected supplier
        manufacturingDate: _manufacturingDate,
        expiryDate: _expiryDate,
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text.replaceAll('-', ''), // Include barcode
      );

      try {
        await apiService.createProduct(newProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto criado com sucesso!')),
        );
        // Clear the form
        _formKey.currentState!.reset();
        _nameController.clear();
        _barcodeController.clear(); // Clear barcode
        _priceBuyController.clear();
        _priceSellController.clear();
        _stockController.clear();
        setState(() {
          _selectedSupplier = 'Nenhum'; // Reset supplier
          _manufacturingDate = DateTime.now();
          _expiryDate = DateTime.now();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar produto: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Produto',
                labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira o nome do produto';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Código de Barras',
                labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                BarcodeTextInputFormatter(),
              ],
            ),
            TextFormField(
              controller: _priceBuyController,
              decoration: InputDecoration(
                labelText: 'Preço de Compra',
                labelStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return 'Por favor, insira um preço válido';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _priceSellController,
              decoration: InputDecoration(
                labelText: 'Preço de Venda',
                labelStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return 'Por favor, insira um preço válido';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'Estoque'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || int.tryParse(value) == null) {
                  return 'Por favor, insira uma quantidade válida';
                }
                return null;
              },
            ),
            DropdownButtonFormField<String>(
              value: _selectedSupplier,
              decoration: const InputDecoration(labelText: 'Fornecedor (Categoria)'),
              items: _suppliers.map((supplier) {
                return DropdownMenuItem(
                  value: supplier,
                  child: Text(supplier),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedSupplier = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione um fornecedor';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // TODO: Adicionar seletores de data para manufacturingDate e expiryDate
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Salvar Produto'),
            ),
          ],
        ),
      ),
    );
  }
}