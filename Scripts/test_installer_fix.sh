#!/bin/bash

# ==============================================================================
# TEST RÁPIDO DE LA CORRECCIÓN DEL INSTALADOR
# ==============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

echo -e "${BLUE}🧪 TEST RÁPIDO DEL INSTALADOR CORREGIDO${NC}"
echo

# Simular algunos contadores globales
TOTAL_INSTALLED=0
TOTAL_SKIPPED=0
TOTAL_FAILED=0

# Funciones básicas para el test
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }

ask_yes_no() {
    local prompt="$1"
    echo -e "${YELLOW}$prompt [y/N]:${NC} y"  # Simular "sí" automático para test
    return 0
}

# Función corregida (copia de la que acabamos de implementar)
install_package_test() {
    local package="$1"
    local repo_hint="$2"      # Solo informativo, NO determinante
    local optional="$3"
    local category="$4"
    local install_mode="$5"
    
    echo -e "\n${CYAN}=== TESTING: $package ===${NC}"
    echo -e "   📋 Hint del JSON: $repo_hint"
    echo -e "   🔧 Opcional: $optional"
    echo -e "   📂 Categoría: $category"
    echo -e "   🎯 Modo: $install_mode"
    
    # Verificar si ya está instalado
    if pacman -Qi "$package" >/dev/null 2>&1; then
        info "📦 $package ya está instalado"
        ((TOTAL_SKIPPED++))
        return 0
    fi
    
    # Verificar modo de instalación para paquetes opcionales
    if [[ "$optional" == "true" ]] && [[ "$install_mode" == "required_only" ]]; then
        info "⏭️  Omitiendo $package (paquete opcional)"
        ((TOTAL_SKIPPED++))
        return 0
    fi
    
    # Preguntar al usuario en modo selectivo
    if [[ "$install_mode" == "selective" ]]; then
        if ! ask_yes_no "¿Instalar $package?"; then
            info "⏭️  Usuario omitió $package"
            ((TOTAL_SKIPPED++))
            return 0
        fi
    fi
    
    info "🔄 Instalando $package (hint: $repo_hint)..."
    
    # ============================================================================
    # LÓGICA INTELIGENTE: SIEMPRE PROBAR PACMAN PRIMERO, LUEGO YAY
    # ============================================================================
    
    local success=false
    local install_method=""
    local error_log=""
    
    # PASO 1: Verificar disponibilidad en pacman
    info "   🔍 Verificando disponibilidad en pacman..."
    if pacman -Si "$package" >/dev/null 2>&1; then
        info "   ✅ Disponible en pacman - SERÍA INSTALADO CON PACMAN"
        success=true
        install_method="pacman (repositorios oficiales)"
    else
        info "   ❌ No disponible en pacman"
        error_log="pacman falló"
        
        # PASO 2: Verificar disponibilidad en yay
        if command -v yay >/dev/null 2>&1; then
            info "   🔍 Verificando disponibilidad en yay..."
            if yay -Si "$package" >/dev/null 2>&1; then
                info "   ✅ Disponible en yay - SERÍA INSTALADO CON YAY"
                success=true
                install_method="yay (AUR)"
            else
                info "   ❌ No disponible en yay"
                error_log="$error_log; yay también falló"
            fi
        else
            error_log="$error_log; yay no disponible"
        fi
    fi
    
    if [[ "$success" == "true" ]]; then
        success "✅ $package SERÍA instalado correctamente con $install_method"
        ((TOTAL_INSTALLED++))
        return 0
    else
        error "❌ Error: $package no está disponible - $error_log"
        ((TOTAL_FAILED++))
        return 1
    fi
}

# ==============================================================================
# EJECUTAR TESTS
# ==============================================================================

echo -e "${YELLOW}📋 Ejecutando tests con paquetes problemáticos...${NC}"

# Test cases que sabemos son problemáticos
test_cases=(
    "amberol|aur|true|16. MUSIC_CLIENTS|selective"
    "stow|pacman|false|1. DOTFILES|full"
    "rmpc-bin|aur|false|16. MUSIC_CLIENTS|full"
    "extension-manager|aur|false|6. DESKTOP_TOOLS|full"
    "cowsay|pacman|true|22. FUN_TOOLS|required_only"
)

readonly CYAN='\033[0;36m'

for test_case in "${test_cases[@]}"; do
    IFS='|' read -r package repo_hint optional category install_mode <<< "$test_case"
    install_package_test "$package" "$repo_hint" "$optional" "$category" "$install_mode"
done

echo
echo -e "${BLUE}📊 RESUMEN DEL TEST:${NC}"
echo -e "   ✅ Paquetes que serían instalados: $TOTAL_INSTALLED"
echo -e "   ⏭️  Paquetes omitidos: $TOTAL_SKIPPED"
echo -e "   ❌ Paquetes que fallarían: $TOTAL_FAILED"

echo
if [[ $TOTAL_FAILED -eq 0 ]]; then
    echo -e "${GREEN}🎉 ¡TEST EXITOSO! La corrección funciona correctamente.${NC}"
else
    echo -e "${YELLOW}⚠️  Algunos paquetes fallarían (probablemente no existen).${NC}"
fi

echo
echo -e "${BLUE}🔧 La corrección principal implementada:${NC}"
echo -e "   • El campo 'repo' del JSON ahora es solo un hint informativo"
echo -e "   • Siempre se intenta pacman primero"
echo -e "   • Si pacman falla, se intenta yay automáticamente"
echo -e "   • Se usa --needed flag para evitar reinstalaciones"
echo -e "   • Mejor logging de qué método funcionó"
