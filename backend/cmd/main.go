package main

import (
	"encoding/json" // <--- ADICIONE ISSO
	"log"
	"net/http"

	"github.com/gorilla/mux"
	
	"e-commerce-backend/internal/database"
	"e-commerce-backend/internal/handlers"
)

// --- ADICIONE ESSA STRUCT ---
type VersionInfo struct {
	Version     string `json:"version"`
	DownloadUrl string `json:"download_url"`
	MustUpdate  bool   `json:"must_update"`
}

// --- ADICIONE ESSE HANDLER ---
func CheckVersionHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	// DICA: Em produção, você leria isso de um arquivo config.json ou do banco
	response := VersionInfo{
		Version:     "1.0.1", // Versão mais nova disponível
		DownloadUrl: "https://seusite.com/downloads/linux/app-latest.tar.gz",
		MustUpdate:  false,
	}
	
	json.NewEncoder(w).Encode(response)
}

func main() {
	// ... (seu código de inicialização do banco continua igual) ...
	database.InitDB()
	repo := database.NewGormProductRepository(database.DB)
	produtoHandler := handlers.NewProdutoHandler(repo)

	r := mux.NewRouter()

	// ... (suas rotas de produtos continuam iguais) ...
	r.HandleFunc("/produtos", produtoHandler.ListarProdutos).Methods("GET")
	r.HandleFunc("/produtos", produtoHandler.CreateProduct).Methods("POST")
	r.HandleFunc("/produtos/{id}", produtoHandler.UpdateProduct).Methods("PUT")
	r.HandleFunc("/produtos/vencendo", produtoHandler.ListarProdutosVencendo).Methods("GET")

	// --- ADICIONE A NOVA ROTA AQUI ---
	r.HandleFunc("/version", CheckVersionHandler).Methods("GET")

	log.Println("🚀 Servidor rodando na porta 8080...")
	if err := http.ListenAndServe(":8080", r); err != nil {
		log.Fatal(err)
	}
}