#!/bin/bash

# TEST SIMPLE PARA DEBUG DEL LOOP DE PAQUETES

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"

# Funciones de logging
info() { echo -e "\033[34m[INFO]\033[0m $*"; }
success() { echo -e "\033[32m[SUCCESS]\033[0m $*"; }
warning() { echo -e "\033[33m[WARNING]\033[0m $*"; }
error() { echo -e "\033[31m[ERROR]\033[0m $*"; }

echo "🧪 DEBUG: LOOP DE PAQUETES"
echo "════════════════════════════════════════════════════════════════════════════"

# Simular install_category para la primera categoría
category_id="1. DOTFILES"
install_mode="selective"

info "📁 Probando categoría: $category_id"

# Obtener información de la categoría desde JSON (EXACTAMENTE como en el script real)
category_info=$(jq --arg cat "$category_id" '.categories[] | select(.id == $cat)' "$PACKAGES_JSON")

if [[ -z "$category_info" ]] || [[ "$category_info" == "null" ]]; then
    error "❌ Categoría '$category_id' no encontrada en packages.json"
    exit 1
fi

emoji=$(echo "$category_info" | jq -r '.emoji // "📦"')
desc=$(echo "$category_info" | jq -r '.description // "Sin descripción"')
packages_count=$(echo "$category_info" | jq '.packages | length')

echo
info "🎯 Instalando: $emoji $category_id"
echo "   📋 $desc"
echo "   📊 $packages_count paquetes en esta categoría"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Vista previa de paquetes en esta categoría
info "   🔍 Paquetes en $category_id:"
for pkg in $(echo "$category_info" | jq -r '.packages[].name'); do
    echo "     - $pkg"
done
echo

# PROCESO MEJORADO - EXACTAMENTE COMO EN EL SCRIPT
current=0
category_installed=0
category_failed=0
category_skipped=0

info "   🔄 Iniciando procesamiento de paquetes..."

# Debug: verificar que tenemos paquetes
package_count_check=$(echo "$category_info" | jq '.packages | length')
info "   📊 Verificación: $package_count_check paquetes detectados"

echo "🔍 DEBUG: Verificando el comando jq antes del loop:"
echo "   Comando: echo \"\$category_info\" | jq -c '.packages[]?'"
echo "   Resultado:"
echo "$category_info" | jq -c '.packages[]?'
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

info "🔄 Iniciando loop while..."

while IFS= read -r package_info; do
    info "   📦 LOOP: Entrada del loop con package_info='$package_info'"
    
    if [[ -n "$package_info" ]] && [[ "$package_info" != "null" ]]; then
        ((current++))
        info "   🔍 Procesando paquete $current de $packages_count..."
        
        name=$(echo "$package_info" | jq -r '.name // ""')
        repo=$(echo "$package_info" | jq -r '.repo // "pacman"')
        optional=$(echo "$package_info" | jq -r '.optional // false')
        desc_pkg=$(echo "$package_info" | jq -r '.description // ""')
        
        info "   📋 Paquete extraído: name='$name', repo='$repo', optional='$optional'"
        
        if [[ -z "$name" ]]; then
            warning "Paquete sin nombre encontrado, omitiendo..."
            continue
        fi
        
        # Mostrar progreso mejorado
        echo
        printf "📦 [%d/%d] %s" "$current" "$packages_count" "$name"
        if [[ -n "$desc_pkg" ]]; then
            printf " - %s" "$desc_pkg"
        fi
        echo
        
        # SIMULAR install_package (sin instalar realmente)
        if pacman -Qi "$name" >/dev/null 2>&1; then
            success "   ✅ $name ya está instalado"
            ((category_skipped++))
        else
            info "   ❓ $name no está instalado"
            echo "   🤔 En modo selectivo, aquí preguntaría: '¿Quieres instalar $name? [s/n]:'"
            ((category_skipped++)) # Simular que el usuario lo saltó
        fi
        
    else
        warning "   ⚠️  Paquete vacío o nulo encontrado: '$package_info'"
    fi
done < <(echo "$category_info" | jq -c '.packages[]?')

info "   ✅ Procesamiento de paquetes completado. Procesados: $current"

# Resumen de la categoría
echo
echo "───────────────────────────────────────────────────────────────"
info "📊 Resumen de $category_id:"
info "   ✅ Instalados: $category_installed"
info "   ❌ Fallidos: $category_failed"
info "   ⏭️  Omitidos: $category_skipped"
echo "───────────────────────────────────────────────────────────────"
echo
info "🔄 Continuando con la siguiente categoría..."
echo

success "✅ DEBUG COMPLETADO - Si llegaste aquí, el loop funciona correctamente"
