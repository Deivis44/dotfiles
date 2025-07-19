#!/bin/bash

# Debug script para verificar la función install_package

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"

# Simular contadores globales
TOTAL_INSTALLED=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log() { echo -e "${BLUE}[DEBUG]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warning() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; }

# Función ask_yes_no simplificada para debug
ask_yes_no() {
    local prompt="$1"
    echo "[SIMULADO] $prompt [y/N]: n (respondiendo automáticamente 'no')"
    return 1  # Simular respuesta 'no'
}

# Función de instalación copiada del script original
install_package() {
    local package="$1"
    local repo="$2"
    local optional="$3"
    local category="$4"
    local install_mode="$5"
    
    log "🔍 Analizando paquete: $package"
    log "   - Repo: $repo"
    log "   - Optional: $optional"
    log "   - Category: $category"
    log "   - Install mode: $install_mode"
    
    # Verificar si ya está instalado
    if pacman -Qi "$package" >/dev/null 2>&1 || yay -Qi "$package" >/dev/null 2>&1; then
        success "📦 $package ya está instalado"
        ((TOTAL_SKIPPED++))
        return 0
    fi
    
    # Verificar modo de instalación para paquetes opcionales
    if [[ "$optional" == "true" ]] && [[ "$install_mode" == "required_only" ]]; then
        warning "⏭️  Omitiendo $package (paquete opcional en modo required_only)"
        ((TOTAL_SKIPPED++))
        return 0
    fi
    
    # Preguntar al usuario en modo selectivo
    if [[ "$install_mode" == "selective" ]]; then
        if ! ask_yes_no "¿Instalar $package?"; then
            warning "⏭️  Usuario omitió $package (modo selectivo)"
            ((TOTAL_SKIPPED++))
            return 0
        fi
    fi
    
    success "🚀 $package SERÍA INSTALADO desde $repo (simulación)"
    ((TOTAL_INSTALLED++))
    return 0
}

test_specific_packages() {
    log "🧪 Testing install_package function..."
    echo
    
    # Test 1: Paquete ya instalado
    log "TEST 1: Paquete ya instalado (stow)"
    install_package "stow" "pacman" "false" "1. DOTFILES" "full"
    echo
    
    # Test 2: Paquete no instalado
    log "TEST 2: Paquete no instalado (amberol)"
    install_package "amberol" "aur" "true" "16. MUSIC_CLIENTS" "full"
    echo
    
    # Test 3: Paquete opcional en modo required_only
    log "TEST 3: Paquete opcional en modo required_only"
    install_package "amberol" "aur" "true" "16. MUSIC_CLIENTS" "required_only"
    echo
    
    # Test 4: Paquete en modo selectivo (simulado como 'no')
    log "TEST 4: Paquete en modo selectivo"
    install_package "amberol" "aur" "true" "16. MUSIC_CLIENTS" "selective"
    echo
    
    log "📊 RESUMEN:"
    log "   - Instalados: $TOTAL_INSTALLED"
    log "   - Omitidos: $TOTAL_SKIPPED"
    log "   - Fallidos: $TOTAL_FAILED"
}

test_category_processing() {
    echo
    log "🔍 Testing category processing..."
    
    # Simular procesamiento de categoría 1. DOTFILES
    local category_id="1. DOTFILES"
    local install_mode="required_only"
    
    log "Procesando categoría: $category_id en modo: $install_mode"
    
    # Obtener información de la categoría
    local category_info
    category_info=$(jq --arg cat "$category_id" '.categories[] | select(.id == $cat)' "$PACKAGES_JSON")
    
    if [[ -z "$category_info" ]] || [[ "$category_info" == "null" ]]; then
        error "Categoría '$category_id' no encontrada"
        return 1
    fi
    
    local packages_count
    packages_count=$(echo "$category_info" | jq '.packages | length')
    log "Paquetes en la categoría: $packages_count"
    
    # Procesar cada paquete
    local current=0
    while IFS= read -r package_info; do
        if [[ -n "$package_info" ]] && [[ "$package_info" != "null" ]]; then
            ((current++))
            
            local name repo optional
            name=$(echo "$package_info" | jq -r '.name // ""')
            repo=$(echo "$package_info" | jq -r '.repo // "pacman"')
            optional=$(echo "$package_info" | jq -r '.optional // false')
            
            if [[ -z "$name" ]]; then
                warning "Paquete sin nombre encontrado, omitiendo..."
                continue
            fi
            
            log "📦 [$current/$packages_count] Procesando: $name"
            install_package "$name" "$repo" "$optional" "$category_id" "$install_mode"
        fi
    done < <(echo "$category_info" | jq -c '.packages[]?')
}

test_all_modes() {
    echo
    log "🎯 Testing all installation modes..."
    
    local modes=("full" "selective" "required_only" "categories")
    
    for mode in "${modes[@]}"; do
        log "Testing mode: $mode"
        
        # Reset counters
        TOTAL_INSTALLED=0
        TOTAL_FAILED=0
        TOTAL_SKIPPED=0
        
        # Test with one package
        install_package "amberol" "aur" "true" "16. MUSIC_CLIENTS" "$mode"
        
        log "Mode $mode results: Installed=$TOTAL_INSTALLED, Skipped=$TOTAL_SKIPPED"
        echo
    done
}

main() {
    echo "🔬 DEBUGGING INSTALACIÓN DE PAQUETES"
    echo "====================================="
    echo
    
    test_specific_packages
    test_category_processing
    test_all_modes
    
    echo
    success "🎉 Debug completo. Revisa el output anterior para identificar problemas."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
