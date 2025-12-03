package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
    "time"

	"github.com/gorilla/mux" // Precisamos disso para pegar o ID na URL
	"e-commerce-backend/internal/database" // Importe seu pacote database
	"e-commerce-backend/internal/models"
)

type ProdutoHandler struct {
	// Agora dependemos da INTERFACE, não do banco concreto (*sql.DB)
	Repo database.ProductRepository
}

// Construtor auxiliar (opcional, mas boa prática)
func NewProdutoHandler(repo database.ProductRepository) *ProdutoHandler {
	return &ProdutoHandler{Repo: repo}
}

// 1. LISTAR (Com suporte a busca por Barcode)
func (h *ProdutoHandler) ListarProdutos(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Verifica se o Flutter mandou ?barcode=123
	barcode := r.URL.Query().Get("barcode")

	if barcode != "" {
		// --- BUSCA ESPECÍFICA ---
		produto, err := h.Repo.GetProductByBarcode(barcode)
		if err != nil {
            // Se não achar, pode retornar 404 ou lista vazia, dependendo da regra.
            // Aqui vamos retornar null/vazio se der erro de "record not found"
			http.Error(w, "Produto não encontrado", http.StatusNotFound)
			return
		}
		json.NewEncoder(w).Encode(produto)
	} else {
		// --- LISTAGEM GERAL ---
		products, err := h.Repo.GetProducts()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		json.NewEncoder(w).Encode(products)
	}
}

// 2. LISTAR VENCENDO (Mantendo sua lógica de filtro, mas usando o Repo)
func (h *ProdutoHandler) ListarProdutosVencendo(w http.ResponseWriter, r *http.Request) {
	// Busca todos via Repository
	allProducts, err := h.Repo.GetProducts()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var produtosVencendo []models.Product

	// Aplica o filtro de vencimento no Go (como você já fazia)
	for _, p := range allProducts {
		if p.IsNearExpiry() {
			produtosVencendo = append(produtosVencendo, p)
		}
	}

	if produtosVencendo == nil {
		produtosVencendo = make([]models.Product, 0)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(produtosVencendo)
}

// 3. CRIAR PRODUTO (POST)
func (h *ProdutoHandler) CreateProduct(w http.ResponseWriter, r *http.Request) {
	var p models.Product
	err := json.NewDecoder(r.Body).Decode(&p)
	if err != nil {
		http.Error(w, "JSON inválido", http.StatusBadRequest)
		return
	}

    // Datas padrão caso venham vazias (opcional)
    if p.ManufacturingDate.IsZero() { p.ManufacturingDate = time.Now() }
    if p.ExpiryDate.IsZero() { p.ExpiryDate = time.Now().AddDate(0, 1, 0) }

	// Chama o Repository (o GORM lá dentro resolve o INSERT)
	if err := h.Repo.CreateProduct(&p); err != nil {
		http.Error(w, "Erro ao criar produto: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(p)
}

// 4. ATUALIZAR PRODUTO (PUT) - NOVO!
func (h *ProdutoHandler) UpdateProduct(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Pega o ID da URL (/produtos/{id})
	vars := mux.Vars(r)
	idStr := vars["id"]
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "ID inválido", http.StatusBadRequest)
		return
	}

	var p models.Product
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "JSON inválido", http.StatusBadRequest)
		return
	}

	// Garante que o ID do objeto é o mesmo da URL
	p.ID = uint(id)

	// Chama o Repository para salvar as alterações
	if err := h.Repo.UpdateProduct(&p); err != nil {
		http.Error(w, "Erro ao atualizar: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Produto atualizado"})
}