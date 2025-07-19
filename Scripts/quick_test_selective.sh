#!/bin/bash

# ==============================================================================
# PRUEBA RÁPIDA DEL INSTALADOR CORREGIDO - Solo primera categoría 
# ==============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"

# Logging con timestamp
log() {
    local level="$1"
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*"
}

info() { log "INFO" "$@"; }
success() { log "SUCCESS" "\033[32m$*\033[0m"; }
warning() { log "WARNING" "\033[33m$*\033[0m"; }
error() { log "ERROR" "\033[31m$*\033[0m"; }

# Contadores globales
TOTAL_INSTALLED=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0

install_package() {
    local package="$1"
    local repo_hint="$2"
    local optional="$3"
    local category="$4"
    local install_mode="$5"
    
    # Verificar si ya está instalado
    if pacman -Qi "$package" >/dev/null 2>&1; then
        success "   ✅ $package ya está instalado"
        ((TOTAL_SKIPPED++))
        return 0
    fi
    
    # Preguntar al usuario en modo selectivo
    if [[ "$install_mode" == "selective" ]]; then
        echo -n "   🤔 ¿Quieres instalar $package? [s/n]: "
        local response
        while true; do
            read -r response
            case "${response,,}" in
                s|si|y|yes) 
                    break
                    ;;
                n|no) 
                    info "   ⏭️  Usuario omitió $package"
                    ((TOTAL_SKIPPED++))
                    return 2
                    ;;
                *) 
                    echo -n "   ❓ Por favor, responde con s/n: "
                    ;;
            esac
        done
    fi
    
    info "   🔄 Instalando $package (hint: $repo_hint)..."
    
    # LÓGICA INTELIGENTE: PROBAR PACMAN PRIMERO, LUEGO YAY
    local success_flag=false
    local install_method=""
    
    # PASO 1: Intentar con pacman
    info "      🔍 Intentando con pacman..."
    if sudo pacman -S --needed --noconfirm "$package" >/dev/null 2>&1; then
        success_flag=true
        install_method="pacman (repositorios oficiales)"
    else
        # PASO 2: Si pacman falla, intentar con yay
        if command -v yay >/dev/null 2>&1; then
            info "      🔍 Pacman falló, intentando con yay..."
            if yay -S --needed --noconfirm "$package" >/dev/null 2>&1; then
                success_flag=true
                install_method="yay (AUR)"
            fi
        fi
    fi
    
    if [[ "$success_flag" == "true" ]]; then
        success "   ✅ $package instalado correctamente con $install_method"
        ((TOTAL_INSTALLED++))
        return 0
    else
        error "   ❌ Error al instalar $package"
        ((TOTAL_FAILED++))
        return 1
    fi
}

# Función principal de prueba
echo "🧪 PRUEBA RÁPIDA - MODO SELECTIVO MEJORADO"
echo "═════════════════════════════════════════════════════════════════"
echo
info "📄 Usando JSON: $PACKAGES_JSON"

# Obtener la primera categoría para prueba
category_info=$(jq '.categories[0]' "$PACKAGES_JSON")
emoji=$(echo "$category_info" | jq -r '.emoji // "📦"')
desc=$(echo "$category_info" | jq -r '.description // "Sin descripción"')
packages_count=$(echo "$category_info" | jq '.packages | length')
category_id=$(echo "$category_info" | jq -r '.id')

echo
info "🎯 Probando: $emoji $category_id"
echo "   📋 $desc"
echo "   📊 $packages_count paquetes en esta categoría"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

current=0
while IFS= read -r package_info; do
    if [[ -n "$package_info" ]] && [[ "$package_info" != "null" ]]; then
        ((current++))
        
        name=$(echo "$package_info" | jq -r '.name // ""')
        repo=$(echo "$package_info" | jq -r '.repo // "pacman"')
        optional=$(echo "$package_info" | jq -r '.optional // false')
        desc_pkg=$(echo "$package_info" | jq -r '.description // ""')
        
        if [[ -z "$name" ]]; then
            warning "Paquete sin nombre encontrado, omitiendo..."
            continue
        fi
        
        echo
        printf "📦 [%d/%d] %s" "$current" "$packages_count" "$name"
        if [[ -n "$desc_pkg" ]]; then
            printf " - %s" "$desc_pkg"
        fi
        echo
        
        # Llamar a la función de instalación en modo selectivo
        install_package "$name" "$repo" "$optional" "$category_id" "selective"
    fi
done < <(echo "$category_info" | jq -c '.packages[]?')

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "📊 Resumen de la prueba:"
info "   ✅ Instalados: $TOTAL_INSTALLED"
info "   ❌ Fallidos: $TOTAL_FAILED" 
info "   ⏭️  Omitidos: $TOTAL_SKIPPED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "✅ Prueba del modo selectivo completada"
echo
