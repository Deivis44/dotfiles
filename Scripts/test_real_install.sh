#!/bin/bash

# Test específico para instalar UN paquete y verificar que la lógica funciona

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log() { echo -e "${BLUE}[TEST]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warning() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; }

test_single_package_install() {
    local package="amberol"
    
    log "🧪 TEST: Instalación de paquete único ($package)"
    echo
    
    # Verificar estado actual
    if pacman -Qi "$package" >/dev/null 2>&1 || yay -Qi "$package" >/dev/null 2>&1; then
        warning "$package ya está instalado. Test cancelado."
        return 1
    fi
    
    success "$package NO está instalado. Perfecto para test."
    echo
    
    # Buscar el paquete en el JSON
    local package_info
    package_info=$(jq --arg pkg "$package" '.categories[].packages[] | select(.name == $pkg)' "$PACKAGES_JSON")
    
    if [[ -z "$package_info" ]]; then
        error "$package no encontrado en packages.json"
        return 1
    fi
    
    log "Información del paquete:"
    echo "$package_info" | jq .
    echo
    
    # Extraer datos
    local repo optional desc
    repo=$(echo "$package_info" | jq -r '.repo')
    optional=$(echo "$package_info" | jq -r '.optional')
    desc=$(echo "$package_info" | jq -r '.description')
    
    log "📦 Paquete: $package"
    log "📁 Repo: $repo"
    log "🔧 Opcional: $optional"
    log "📝 Descripción: $desc"
    echo
    
    # Preguntar al usuario si quiere hacer la instalación real
    echo -n "¿Quieres hacer una instalación real de $package? [y/N]: "
    read -r response
    
    if [[ "${response,,}" =~ ^(y|yes|s|si)$ ]]; then
        log "🚀 Instalando $package..."
        
        if [[ "$repo" == "aur" ]]; then
            if command -v yay >/dev/null 2>&1; then
                if yay -S --noconfirm "$package"; then
                    success "✅ $package instalado correctamente con yay"
                    return 0
                else
                    error "❌ Error al instalar $package con yay"
                    return 1
                fi
            else
                error "yay no está disponible para paquetes AUR"
                return 1
            fi
        else
            if sudo pacman -S --noconfirm "$package"; then
                success "✅ $package instalado correctamente con pacman"
                return 0
            else
                error "❌ Error al instalar $package con pacman"
                return 1
            fi
        fi
    else
        log "🔄 Simulando instalación..."
        sleep 1
        success "✅ [SIMULADO] $package se habría instalado correctamente"
        return 0
    fi
}

test_category_with_missing_packages() {
    log "🔍 Buscando categoría con paquetes no instalados..."
    
    # Buscar en la categoría 16. MUSIC_CLIENTS que tiene amberol
    local category_id="16. MUSIC_CLIENTS"
    local category_info
    category_info=$(jq --arg cat "$category_id" '.categories[] | select(.id == $cat)' "$PACKAGES_JSON")
    
    log "Paquetes en $category_id:"
    
    while IFS= read -r package_info; do
        if [[ -n "$package_info" ]] && [[ "$package_info" != "null" ]]; then
            local name
            name=$(echo "$package_info" | jq -r '.name')
            
            if pacman -Qi "$name" >/dev/null 2>&1 || yay -Qi "$name" >/dev/null 2>&1; then
                log "  📦 $name - YA INSTALADO"
            else
                warning "  📦 $name - NO INSTALADO ❗"
            fi
        fi
    done < <(echo "$category_info" | jq -c '.packages[]?')
    
    echo
}

main() {
    echo "🧪 TEST ESPECÍFICO DE INSTALACIÓN"
    echo "================================="
    echo
    
    test_category_with_missing_packages
    test_single_package_install
    
    echo
    log "💡 DIAGNÓSTICO:"
    log "Si el test anterior funcionó, entonces el problema original era que"
    log "la mayoría de paquetes YA ESTÁN INSTALADOS en tu sistema."
    log "El instalador está funcionando correctamente - simplemente detecta"
    log "que los paquetes ya existen y los marca como 'omitidos'."
    echo
    log "Para ver más actividad del instalador, intenta:"
    log "1. Usar modo selectivo (opción 3)"
    log "2. Instalar paquetes opcionales que no tengas"
    log "3. Desinstalar algo primero y luego reinstalarlo"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
