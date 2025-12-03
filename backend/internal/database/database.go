package database

import (
	"log"
	"os"
	"path/filepath"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"e-commerce-backend/internal/models"
)

var DB *gorm.DB

// 1. INTERFACE (O Contrato)
// Define QUAIS MÉTODOS o nosso repositório de produtos DEVE ter.
// Isso desacopla a lógica de negócio (handlers) da implementação do banco (GORM).
type ProductRepository interface {
	GetProducts() ([]models.Product, error)
	GetProductByBarcode(barcode string) (*models.Product, error)
	CreateProduct(product *models.Product) error
	UpdateProduct(product *models.Product) error
}

// 2. STRUCT (A Implementação Concreta)
// Esta struct vai implementar os métodos definidos na interface acima,
// usando GORM para interagir com o banco de dados.
type GormProductRepository struct{}

func InitDB() {
	var err error

	// 1. Localização Profissional (Pasta do Usuário no Linux)
	// Isso garante que o update do App (que substitui a pasta /opt) NÃO apague o banco.
	homeDir, _ := os.UserHomeDir()
	appDir := filepath.Join(homeDir, ".meuapp-ecommerce")
	dbPath := filepath.Join(appDir, "ecommerce_pro.db")

	// Garante que a pasta existe
	if _, err := os.Stat(appDir); os.IsNotExist(err) {
		os.MkdirAll(appDir, 0755)
	}

	// 2. Configuração do Logger
	dbConfig := &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	}

	DB, err = gorm.Open(sqlite.Open(dbPath), dbConfig)
	if err != nil {
		log.Fatalf("❌ Erro fatal ao conectar no banco: %v", err)
	}

	// 3. OTIMIZAÇÃO DE PERFORMANCE (O Segredo)
	// WAL Mode: Permite leitura e escrita simultâneas (App não trava salvando venda)
	DB.Exec("PRAGMA journal_mode = WAL")
	// Foreign Keys: Garante integridade (Não deixa apagar categoria se tiver produto nela)
	DB.Exec("PRAGMA foreign_keys = ON")

	log.Println("🛠️ Rodando Migrations Relacionais...")

	// 4. Auto-Migração na Ordem Certa
	err = DB.AutoMigrate(
		&models.Category{},      // 1º Criar Categoria
		&models.Product{},       // 2º Criar Produto (que usa Categoria)
		&models.StockMovement{}, // 3º Criar Histórico (que usa Produto)
	)

	if err != nil {
		log.Fatalf("❌ Erro na migração: %v", err)
	}

	// 5. Seed Inicial (Garante que existe Categoria ID 1)
	var count int64
	DB.Model(&models.Category{}).Count(&count)
	if count == 0 {
		log.Println("🌱 Criando categoria padrão 'Geral'...")
		DB.Create(&models.Category{Name: "Geral", Description: "Categoria Padrão"})
	}

	log.Printf("✅ Banco Profissional Iniciado em: %s", dbPath)
}

// 3. CONSTRUTOR (Como criar uma instância do repositório)
// Esta função retorna uma nova instância da nossa implementação GORM.
func NewGormProductRepository(db *gorm.DB) ProductRepository {
	return &GormProductRepository{}
}

// --- IMPLEMENTAÇÃO DOS MÉTODOS DA INTERFACE ---

func (r *GormProductRepository) GetProducts() ([]models.Product, error) {
	var products []models.Product
	// Usamos Preload("Category") para trazer os dados da categoria junto
	err := DB.Preload("Category").Find(&products).Error
	return products, err
}

func (r *GormProductRepository) GetProductByBarcode(barcode string) (*models.Product, error) {
	var product models.Product
	err := DB.Preload("Category").Where("barcode = ?", barcode).First(&product).Error
	return &product, err
}

func (r *GormProductRepository) CreateProduct(product *models.Product) error {
	return DB.Create(product).Error
}

func (r *GormProductRepository) UpdateProduct(product *models.Product) error {
	return DB.Save(product).Error
}
