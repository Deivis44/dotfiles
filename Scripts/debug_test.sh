#!/bin/bash

# ==============================================================================
# DEBUG TEST - Verificación rápida del sistema JSON
# ==============================================================================

set -euo pipefail

# Configuraciones
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[DEBUG]${NC} $*"
}

success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

error() {
    echo -e "${RED}[✗]${NC} $*"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $*"
}

echo "🔍 DEBUG TEST - Verificación del sistema JSON"
echo "=============================================="
echo

# 1. Verificar archivo JSON existe
log "1. Verificando existencia del archivo JSON..."
if [[ -f "$PACKAGES_JSON" ]]; then
    success "Archivo existe: $PACKAGES_JSON"
else
    error "Archivo NO existe: $PACKAGES_JSON"
    exit 1
fi
echo

# 2. Verificar que jq está disponible
log "2. Verificando jq..."
if command -v jq >/dev/null 2>&1; then
    success "jq está disponible: $(jq --version)"
else
    error "jq NO está disponible"
    exit 1
fi
echo

# 3. Verificar validez del JSON
log "3. Verificando validez del JSON..."
if jq empty "$PACKAGES_JSON" 2>/dev/null; then
    success "JSON es válido"
else
    error "JSON NO es válido"
    jq . "$PACKAGES_JSON" 2>&1 | head -10
    exit 1
fi
echo

# 4. Verificar estructura del JSON
log "4. Verificando estructura del JSON..."
echo "   📊 Estructura general:"
echo "      - Archivo tamaño: $(wc -c < "$PACKAGES_JSON") bytes"
echo "      - Líneas: $(wc -l < "$PACKAGES_JSON")"

# Verificar que tiene la estructura esperada
if jq -e '.categories' "$PACKAGES_JSON" >/dev/null 2>&1; then
    total_categories=$(jq '.categories | length' "$PACKAGES_JSON")
    success "Estructura válida - Categorías encontradas: $total_categories"
else
    error "Estructura inválida - No se encontró '.categories'"
    exit 1
fi
echo

# 5. Test del comando exacto que falla
log "5. Testando el comando exacto que falla en el script..."
echo "   📝 Comando: jq -r '.categories[].id' \"\$PACKAGES_JSON\""
echo

categories=()
count=0
while IFS= read -r category_id; do
    if [[ -n "$category_id" ]] && [[ "$category_id" != "null" ]]; then
        categories+=("$category_id")
        echo "      ✓ Categoría $((++count)): $category_id"
    else
        warning "Línea vacía o null encontrada: '$category_id'"
    fi
done < <(jq -r '.categories[].id' "$PACKAGES_JSON" 2>/dev/null)

echo
if [[ ${#categories[@]} -eq 0 ]]; then
    error "❌ PROBLEMA REPRODUCIDO: No se pudieron leer categorías"
    echo
    log "Diagnóstico adicional:"
    echo "   🔍 Comando directo:"
    jq -r '.categories[].id' "$PACKAGES_JSON" 2>&1 | head -10
    echo
    echo "   🔍 Estructura de categorías:"
    jq '.categories[0:3]' "$PACKAGES_JSON" 2>/dev/null || echo "Error al leer categorías"
else
    success "✅ ÉXITO: Se leyeron ${#categories[@]} categorías correctamente"
    echo "   📋 Categorías encontradas: ${categories[*]}"
fi
echo

# 6. Test adicional - verificar permisos
log "6. Verificando permisos del archivo..."
ls -la "$PACKAGES_JSON"
echo

# 7. Test de diferentes métodos de lectura
log "7. Probando métodos alternativos de lectura..."

echo "   📝 Método 1 - jq directo:"
if jq -r '.categories[].id' "$PACKAGES_JSON" | head -5; then
    success "Método 1 funciona"
else
    error "Método 1 falla"
fi
echo

echo "   📝 Método 2 - con pipe explícito:"
if jq -r '.categories[] | .id' "$PACKAGES_JSON" | head -5; then
    success "Método 2 funciona"
else
    error "Método 2 falla"
fi
echo

echo "   📝 Método 3 - verificando primera categoría:"
if jq -r '.categories[0].id' "$PACKAGES_JSON"; then
    success "Método 3 funciona"
else
    error "Método 3 falla"
fi
echo

# 8. Información del sistema
log "8. Información del sistema:"
echo "   🖥️  Sistema: $(uname -a)"
echo "   🏠 Usuario: $(whoami)"
echo "   📁 PWD: $(pwd)"
echo "   🔧 Shell: $SHELL"
echo "   📦 jq versión: $(jq --version 2>/dev/null || echo 'N/A')"
echo

echo "🏁 DEBUG TEST COMPLETADO"
echo "========================"
