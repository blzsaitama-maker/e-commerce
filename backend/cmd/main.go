package main

import (
	"log"
	"net/http"

	"e-commerce-backend/internal/database"
	"e-commerce-backend/internal/handlers"
)

func main() {
	// 1. Inicializa e conecta ao banco de dados
	database.InitDB()
	sqlDB, err := database.DB.DB()
	if err != nil {
		log.Fatalf("Failed to get underlying sql.DB: %v", err)
	}
	// Se estiver usando GORM, certifique-se que 'db' é do tipo *gorm.DB

	// 2. Inicializa o Handler
	produtoHandler := &handlers.ProdutoHandler{DB: sqlDB}

	// 3. Define as Rotas

	// Rota Principal (/produtos): Aceita GET (Listar) e POST (Criar)
	http.HandleFunc("/produtos", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			produtoHandler.ListarProdutos(w, r)
		} else if r.Method == http.MethodPost {
			produtoHandler.CreateProduct(w, r)
		} else {
			http.Error(w, "Método não permitido", http.StatusMethodNotAllowed)
		}
	})

	// Rota de Filtro (/produtos/vencendo): Apenas GET
	http.HandleFunc("/produtos/vencendo", produtoHandler.ListarProdutosVencendo)

	// 4. Inicia o Servidor
	log.Println("🚀 Servidor rodando na porta 8080...")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}