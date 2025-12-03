package database

import (
	"log"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"e-commerce-backend/internal/models" 
)

var DB *gorm.DB

// 1. A Interface (O Contrato)
// Aqui definimos o que o sistema pode fazer, sem saber SE é GORM ou SQL puro.
type ProductRepository interface {
	CreateProduct(product *models.Product) error
	GetProducts() ([]models.Product, error)
	GetProductByBarcode(barcode string) (*models.Product, error) // Novo para o seu Flutter
	UpdateProduct(product *models.Product) error
}

// 2. A Struct que implementa a interface usando GORM
type GormProductRepository struct {
	db *gorm.DB
}

// Função auxiliar para criar o repository
func NewGormProductRepository(db *gorm.DB) *GormProductRepository {
	return &GormProductRepository{db: db}
}

// --- Implementação das Funções (Usando sintaxe GORM) ---

// Criar
func (r *GormProductRepository) CreateProduct(product *models.Product) error {
	return r.db.Create(product).Error
}

// Listar Todos
func (r *GormProductRepository) GetProducts() ([]models.Product, error) {
	var products []models.Product
	// Find no GORM é igual ao "SELECT *"
	result := r.db.Find(&products)
	return products, result.Error
}

// Buscar por Código de Barras (Para o seu Flutter pesquisar)
func (r *GormProductRepository) GetProductByBarcode(barcode string) (*models.Product, error) {
	var product models.Product
	// Busca onde o codigo_barras (ajuste o nome do campo conforme sua model) é igual
	// Assumindo que na struct Product o campo é 'Barcode'
	result := r.db.Where("barcode = ?", barcode).First(&product)
	
	if result.Error != nil {
		return nil, result.Error
	}
	return &product, nil
}

// Atualizar (Para quando você clicar em Salvar no Flutter editando)
func (r *GormProductRepository) UpdateProduct(product *models.Product) error {
	// Save no GORM atualiza se tiver ID, ou cria se não tiver. 
	// Mas como garantimos que tem ID no handler, ele vai atualizar.
	return r.db.Save(product).Error
}

// --- Seu código original de conexão ---

func InitDB() {
	var err error
	DB, err = gorm.Open(sqlite.Open("ecommerce.db"), &gorm.Config{})
	if err != nil {
		log.Fatalf("Falha ao conectar com o banco de dados: %v", err)
	}

	// Migrate the schema
	err = DB.AutoMigrate(&models.Product{})
	if err != nil {
		log.Fatalf("Falha ao migrar o esquema do banco de dados: %v", err)
	}

	log.Println("Conexão com o banco de dados e migração concluídas com sucesso!")
}