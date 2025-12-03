package models

import (
	"time"

	"gorm.io/gorm"
)

// --- 1. CATEGORIA (Normalização) ---
// Evita repetir texto. "Bebidas" vira ID 1.
type Category struct {
	ID          uint   `json:"id" gorm:"primarykey"`
	Name        string `json:"name" gorm:"unique;not null"`
	Description string `json:"description"`
}

// --- 2. PRODUTO (Relacional) ---
type Product struct {
	gorm.Model `json:"-"` // Oculta campos internos do GORM
	ID         uint       `json:"id" gorm:"primarykey"`

	// Index para deixar a busca por nome muito rápida
	Name string `json:"name" gorm:"index;not null"`

	// Código de Barras ÚNICO (Impede duplicidade)
	Barcode string `json:"barcode" gorm:"uniqueIndex;not null;default:''"`

	PriceBuy  float64 `json:"price_buy" gorm:"not null"`
	PriceSell float64 `json:"price_sell" gorm:"not null"`

	Stock    int `json:"stock" gorm:"not null;default:0"`
	MinStock int `json:"min_stock" gorm:"default:5"` // Para alertas

	// Chave Estrangeira para Categoria
	CategoryID uint     `json:"category_id"`
	Category   Category `json:"category" gorm:"foreignKey:CategoryID"`

	ManufacturingDate time.Time `json:"manufacturing_date"`
	ExpiryDate        time.Time `json:"expiry_date" gorm:"index"` // Index para ordenar validade
}

// --- 3. AUDITORIA DE ESTOQUE (Rastreabilidade) ---
// Registra CADA mudança no estoque. Nunca apague dados daqui.
type StockMovement struct {
	gorm.Model `json:"-"`
	ID         uint `json:"id" gorm:"primarykey"`

	ProductID uint    `json:"product_id" gorm:"not null"`
	Product   Product `json:"-" gorm:"foreignKey:ProductID"`

	Type     string `json:"type" gorm:"not null"` // "IN" (Entrada), "OUT" (Saída), "ADJUST" (Ajuste)
	Quantity int    `json:"quantity" gorm:"not null"`
	Reason   string `json:"reason"` // Ex: "Venda #102", "Perda", "Compra NF 50"
}

// Lógica de Vencimento
func (p *Product) IsNearExpiry() bool {
	if p.ExpiryDate.IsZero() {
		return false
	}
	totalLife := p.ExpiryDate.Sub(p.ManufacturingDate)
	alertDuration := totalLife / 5
	triggerDate := p.ExpiryDate.Add(-alertDuration)
	return time.Now().After(triggerDate)
}
