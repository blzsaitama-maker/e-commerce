package models

import (
	"time"

	"gorm.io/gorm"
)

type Product struct {
	gorm.Model        `json:"-"` // Oculta os campos padrão do GORM do JSON principal
	ID                uint       `json:"id" gorm:"primarykey"` // Expõe o ID explicitamente
	Name              string     `json:"name" gorm:"not null"`
	PriceBuy          float64    `json:"price_buy" gorm:"not null"`
	PriceSell         float64    `json:"price_sell" gorm:"not null"`
	Stock             int        `json:"stock" gorm:"not null"`
	Category          string     `json:"category"`
	ManufacturingDate time.Time  `json:"manufacturing_date"`
	ExpiryDate        time.Time  `json:"expiry_date"`
	Barcode           string     `json:"barcode" gorm:"not null;default:''"` // New field, now mandatory
}

// IsNearExpiry verifica se o produto já passou de 80% da vida útil
func (p *Product) IsNearExpiry() bool {
	// 1. Calcula a vida total do produto (Vencimento - Fabricação)
	totalLife := p.ExpiryDate.Sub(p.ManufacturingDate)

	// 2. Calcula o tempo de alerta (20% do total)
	// Usamos divisão por 5 para manter tudo como número inteiro (time.Duration)
	alertDuration := totalLife / 5

	// 3. Define a data de disparo do alerta (Vencimento - Tempo de Alerta)
	// Ex: Se vence dia 30 e o alerta é 5 dias, o gatilho é dia 25.
	triggerDate := p.ExpiryDate.Add(-alertDuration)

	// 4. Verifica se "Agora" já passou dessa data de gatilho
	return time.Now().After(triggerDate)
}

// CreateProduct insere um novo registro de produto no banco de dados.
func CreateProduct(db *gorm.DB, product *Product) error {
	// O GORM gera o SQL de insert automaticamente baseado na struct
	return db.Create(product).Error
}

// DeleteProduct remove (soft delete) um produto pelo ID.
func DeleteProduct(db *gorm.DB, id uint) error {
	// Passamos &Product{} para o GORM saber qual tabela usar.
	return db.Delete(&Product{}, id).Error
}

// GetProductTableSchema retorna o SQL bruto para criação da tabela.
// (Renomeado para evitar conflito com a função de criar o registro acima)
func GetProductTableSchema() string {
	return `CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        preco_buy REAL NOT NULL,
        preco_sell REAL NOT NULL,
        stock INTEGER NOT NULL,
        category TEXT,
        manufacturing_date DATETIME,
        expiry_date DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        barcode TEXT NOT NULL,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );`
}
