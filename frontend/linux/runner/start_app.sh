#!/bin/bash

# --- CONFIGURAÇÕES DO APLICATIVO ---
APP_DIR="$HOME/meuapp-gestao"
BACKEND_BIN="$APP_DIR/backend_bin"
FRONTEND_BIN="$APP_DIR/frontend_app"
LOG_FILE="$APP_DIR/startup.log"
APP_NAME="SistemaGestaoPDV"

# 1. FUNÇÃO PARA INICIAR O BACKEND GO EM BACKGROUND
start_backend() {
    echo "$(date): Tentando iniciar o backend..." >> "$LOG_FILE"
    # O binário do Go deve estar compilado e movido para $BACKEND_BIN
    # Redireciona a saída do Go para o log
    if [ -x "$BACKEND_BIN" ]; then
        nohup "$BACKEND_BIN" > "$APP_DIR/backend.log" 2>&1 &
        BACKEND_PID=$!
        echo "$(date): Backend iniciado com PID: $BACKEND_PID" >> "$LOG_FILE"
        sleep 5 # Dá tempo para o banco SQLite e o servidor HTTP iniciarem
    else
        echo "$(date): ERRO: Binário do Backend não encontrado ou não é executável em $BACKEND_BIN" >> "$LOG_FILE"
    fi
}

# 2. FUNÇÃO PARA GARANTIR QUE OS PROCESSOS MORREM AO FECHAR
cleanup() {
    echo "$(date): Aplicativo Frontend fechado. Terminando o Backend..." >> "$LOG_FILE"
    pkill -f "$BACKEND_BIN"
    echo "$(date): Backend terminado." >> "$LOG_FILE"
    exit 0
}
trap cleanup EXIT # Executa a função cleanup quando o script for encerrado

# --- INICIALIZAÇÃO PRINCIPAL ---

# Garantir que a pasta exista (importante para o instalador)
mkdir -p "$APP_DIR"

# 1. Inicia o Backend (Primeiro, sempre!)
start_backend

# 2. Inicia o Frontend Flutter (O Binário compilado do Flutter)
echo "$(date): Iniciando Frontend Flutter..." >> "$LOG_FILE"

# O binário do Flutter deve estar em $FRONTEND_BIN
# Este comando BLOQUEIA o script até que o Flutter seja fechado.
if [ -x "$FRONTEND_BIN" ]; then
    "$FRONTEND_BIN"
else
    echo "$(date): ERRO: Binário do Frontend não encontrado ou não é executável em $FRONTEND_BIN" >> "$LOG_FILE"
    # Se o frontend falhar, o trap EXIT vai garantir que o backend morra.
fi

# A função cleanup (trap) será chamada aqui.