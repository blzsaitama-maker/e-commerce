package database

import (
	"log"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"e-commerce-backend/internal/models" // Adjust import path if necessary
)

var DB *gorm.DB

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

	// Workaround for SQLite "Cannot add a NOT NULL column with default value NULL" error:
	// If you encounter this error on an existing database, it's because SQLite's ALTER TABLE
	// limitations prevent adding a NOT NULL column to a table with existing data without
	// a complex table recreation process.
	// For development, consider deleting the 'ecommerce.db' file to allow AutoMigrate
	// to create the schema correctly from scratch. For production, a more robust
	// migration strategy (e.g., dedicated migration tool or manual table recreation logic)
	// would be necessary.

	log.Println("Conexão com o banco de dados e migração concluídas com sucesso!")
}