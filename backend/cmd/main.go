package main

import (
	"log"
	"net/http"

	"github.com/gorilla/mux" // Importante: Garanta que baixou isso (go get github.com/gorilla/mux)
	
	"e-commerce-backend/internal/database"
	"e-commerce-backend/internal/handlers"
)

func main() {
	// 1. Inicializa o banco de dados (GORM)
	// Isso preenche a variável database.DB
	database.InitDB()

	// 2. INJEÇÃO DE DEPENDÊNCIA (O Pulo do Gato)
	// Criamos o Repositório usando a conexão do banco
	repo := database.NewGormProductRepository(database.DB)

	// Criamos o Handler injetando o Repositório nele
	// Agora o Handler não sabe que é SQLite, só sabe que tem um Repositório
	produtoHandler := handlers.NewProdutoHandler(repo)

	// 3. Configura o Roteador (Gorilla Mux)
	r := mux.NewRouter()

	// --- ROTAS ---

	// GET /produtos -> Lista tudo OU busca por ?barcode=...
	r.HandleFunc("/produtos", produtoHandler.ListarProdutos).Methods("GET")

	// POST /produtos -> Cria novo produto
	r.HandleFunc("/produtos", produtoHandler.CreateProduct).Methods("POST")

	// PUT /produtos/{id} -> Atualiza produto existente (NOVA ROTA)
	// O {id} é capturado pelo mux.Vars no handler
	r.HandleFunc("/produtos/{id}", produtoHandler.UpdateProduct).Methods("PUT")

	// GET /produtos/vencendo -> Filtro de validade
	r.HandleFunc("/produtos/vencendo", produtoHandler.ListarProdutosVencendo).Methods("GET")

	// 4. Inicia o Servidor
	log.Println("🚀 Servidor rodando na porta 8080 com Mux e Repository Pattern...")
	
	// Passamos o 'r' (router) em vez de nil
	if err := http.ListenAndServe(":8080", r); err != nil {
		log.Fatal(err)
	}
}