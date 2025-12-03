import 'package:flutter/material.dart';
import 'package:frontend/features/products/widgets/product_list_widget.dart'; // Lista que fizemos
import 'package:frontend/features/products/screens/product_form_screen.dart'; // Seus formulários
import 'package:frontend/features/sales/screens/sales_screen.dart'; // Suas vendas

// Este Widget agora gerencia a navegação entre as telas principais
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Lista de Widgets que serão exibidos
  final List<Widget> _pages = [
    const ProductListWidget(),    // 0: Lista de Produtos (Início)
    const SalesScreen(),          // 1: Tela de Vendas (Implementada por você)
    const ProductFormScreen(),    // 2: Tela de Cadastro de Produtos
  ];

  // Índice da página atualmente selecionada
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // A versão fixa do app (usada para a checagem de update)
  final String currentAppVersion = "1.0.1"; 
  
  // URL de checagem da versão
  final String versionCheckUrl = 'http://127.0.0.1:8080/version';

  @override
  void initState() {
    super.initState();
    // A checagem de update agora é feita ao iniciar o app
    // Como esta lógica ainda não está completa, vamos deixá-la aqui.
    // _checkForUpdates(); 
  }

  // Lógica de checagem de update (Deixada aqui, mas desativada por enquanto)
  /*
  Future<void> _checkForUpdates() async {
    // Código de checagem de update
    // ...
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Gestão E-commerce'),
        actions: [
          // Exemplo de botão para o futuro: mostrar o formulário de cadastro
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'Ir para Cadastro',
            onPressed: () {
              // Navega diretamente para a aba de cadastro (índice 2)
              _onItemTapped(2);
            },
          ),
          // Botão para forçar a checagem de atualização
          IconButton(
            icon: const Icon(Icons.update),
            tooltip: 'Checar Atualizações',
            onPressed: () {
              // _checkForUpdates(); // Reativar quando o método _checkForUpdates estiver completo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Função de atualização em desenvolvimento...'))
              );
            },
          ),
        ],
      ),
      
      // Corpo: Exibe a tela atualmente selecionada
      body: _pages[_selectedIndex],

      // Barra de Navegação Inferior
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Estoque',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Vendas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Cadastro Prod.',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}