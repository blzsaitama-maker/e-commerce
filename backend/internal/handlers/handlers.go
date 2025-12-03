package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
	"e-commerce-backend/internal/database"
	"e-commerce-backend/internal/models"
)

type ProdutoHandler struct {
	Repo database.ProductRepository
}

func NewProdutoHandler(repo database.ProductRepository) *ProdutoHandler {
	return &ProdutoHandler{Repo: repo}
}

// LISTAR
func (h *ProdutoHandler) ListarProdutos(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	barcode := r.URL.Query().Get("barcode")

	if barcode != "" {
		produto, err := h.Repo.GetProductByBarcode(barcode)
		if err != nil {
			// Retorna JSON vazio ou erro 404 limpo
			w.WriteHeader(http.StatusNotFound)
			json.NewEncoder(w).Encode(map[string]string{"error": "Produto não encontrado"})
			return
		}
		// Preload da Categoria para o Frontend mostrar o nome
		// (Isso depende se o seu Repo faz Preload, se não, retorna só o ID)
		json.NewEncoder(w).Encode(produto)
	} else {
		products, err := h.Repo.GetProducts()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		json.NewEncoder(w).Encode(products)
	}
}

// LISTAR VENCENDO
func (h *ProdutoHandler) ListarProdutosVencendo(w http.ResponseWriter, r *http.Request) {
	allProducts, err := h.Repo.GetProducts()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	produtosVencendo := []models.Product{}
	for _, p := range allProducts {
		if p.IsNearExpiry() {
			produtosVencendo = append(produtosVencendo, p)
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(produtosVencendo)
}

// CRIAR
func (h *ProdutoHandler) CreateProduct(w http.ResponseWriter, r *http.Request) {
	var p models.Product
	
	// Tenta decodificar o JSON
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "JSON inválido", http.StatusBadRequest)
		return
	}

	// --- LÓGICA DE PROTEÇÃO (MVP) ---
	// Se o frontend mandar sem Categoria, forçamos a Categoria 1 (Geral)
	// Isso evita erro de Foreign Key no banco
	if p.CategoryID == 0 {
		p.CategoryID = 1
	}

	// Datas padrão se vierem vazias
	if p.ManufacturingDate.IsZero() {
		p.ManufacturingDate = time.Now()
	}
	if p.ExpiryDate.IsZero() {
		p.ExpiryDate = time.Now().AddDate(0, 1, 0) // +1 mês padrão
	}

	if err := h.Repo.CreateProduct(&p); err != nil {
		// Retorna erro detalhado (provavelmente barcode duplicado)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(p)
}

// ATUALIZAR
func (h *ProdutoHandler) UpdateProduct(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	var p models.Product
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "JSON inválido", http.StatusBadRequest)
		return
	}

	p.ID = uint(id)
	
	// Proteção de categoria na edição também
	if p.CategoryID == 0 {
		p.CategoryID = 1
	}

	if err := h.Repo.UpdateProduct(&p); err != nil {
		http.Error(w, "Erro ao atualizar: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Produto atualizado com sucesso"})
}