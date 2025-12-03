package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"

	"e-commerce-backend/internal/models"
)

type ProdutoHandler struct {
	DB *sql.DB
}

func (h *ProdutoHandler) ListarProdutos(w http.ResponseWriter, r *http.Request) {
	rows, err := h.DB.Query("SELECT id, name, price_buy, price_sell, stock, category, manufacturing_date, expiry_date FROM products")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var products []models.Product
	for rows.Next() {
		var p models.Product
		if err := rows.Scan(&p.ID, &p.Name, &p.PriceBuy, &p.PriceSell, &p.Stock, &p.Category, &p.ManufacturingDate, &p.ExpiryDate); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		products = append(products, p)
	}

	if err := rows.Err(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if products == nil {
		products = make([]models.Product, 0)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(products)
}

func (h *ProdutoHandler) ListarProdutosVencendo(w http.ResponseWriter, r *http.Request) {
	// 1. Busca todos os produtos do banco
	rows, err := h.DB.Query("SELECT id, name, price_buy, price_sell, stock, category, manufacturing_date, expiry_date FROM products")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var produtosVencendo []models.Product // Começa uma lista vazia

	for rows.Next() {
		var p models.Product
		// Preenchemos os dados do produto 'p'
		if err := rows.Scan(&p.ID, &p.Name, &p.PriceBuy, &p.PriceSell, &p.Stock, &p.Category, &p.ManufacturingDate, &p.ExpiryDate); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// 2. O Filtro: Só adiciona se estiver vencendo (20% finais)
		if p.IsNearExpiry() {
			produtosVencendo = append(produtosVencendo, p)
		}
	}

	// 3. Retorna a lista filtrada como JSON
	if produtosVencendo == nil {
		produtosVencendo = make([]models.Product, 0)
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(produtosVencendo)
}

func(h *ProdutoHandler) CreateProduct(w http.ResponseWriter, r *http.Request) {
	var p models.Product
	err := json.NewDecoder(r.Body).Decode(&p)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	stmt, err := h.DB.Prepare("INSERT INTO products(name, price_buy, price_sell, stock, category, manufacturing_date, expiry_date) VALUES(?,?,?,?,?,?,?)")
	if err != nil {
		http.Error(w, "Failed to prepare statement: "+err.Error(), http.StatusInternalServerError)
		return
	}
	defer stmt.Close()

	res, err := stmt.Exec(p.Name, p.PriceBuy, p.PriceSell, p.Stock, p.Category, p.ManufacturingDate, p.ExpiryDate)
	if err != nil {
		http.Error(w, "Failed to execute statement: "+err.Error(), http.StatusInternalServerError)
		return
	}

	id, err := res.LastInsertId()
	if err != nil {
		http.Error(w, "Failed to get last insert ID: "+err.Error(), http.StatusInternalServerError)
		return
	}
	p.ID = uint(id)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(p)
}