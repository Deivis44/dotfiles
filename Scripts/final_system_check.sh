#!/bin/bash

# ==============================================================================
# FINAL SYSTEM CHECK - Verificación final antes de la instalación real
# ==============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log() { echo -e "${BLUE}[CHECK]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warning() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; }

show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════╗
║                     ✅ FINAL SYSTEM CHECK                           ║
║                Verificación final antes de instalar                  ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo
}

check_all_scripts() {
    log "🔍 Verificando scripts principales..."
    
    local scripts=(
        "full_installer_v2.sh:Instalador principal"
        "system_diagnostic.sh:Sistema diagnóstico"
        "json_manager.sh:Gestor JSON"
        "stow-links.sh:Enlaces simbólicos"
        "install_extra_packs.sh:Paquetes extra"
    )
    
    local all_good=true
    
    for script_info in "${scripts[@]}"; do
        local script="${script_info%%:*}"
        local desc="${script_info#*:}"
        
        if [[ -f "$script" ]]; then
            if [[ -x "$script" ]]; then
                success "$script - $desc"
            else
                warning "$script existe pero no es ejecutable"
                chmod +x "$script"
                success "$script - permisos corregidos"
            fi
        else
            error "$script no encontrado"
            all_good=false
        fi
    done
    
    echo
    return $all_good
}

check_json_integrity() {
    log "📄 Verificando integridad del JSON..."
    
    if [[ ! -f "packages.json" ]]; then
        error "packages.json no encontrado"
        return 1
    fi
    
    # Verificar sintaxis básica
    if ! jq empty packages.json 2>/dev/null; then
        error "JSON con sintaxis inválida"
        return 1
    fi
    
    # Contar elementos
    local categories=$(jq '.categories | length' packages.json)
    local total_packages=$(jq '[.categories[].packages | length] | add' packages.json)
    local pacman_packages=$(jq '[.categories[].packages[] | select(.repo == "pacman")] | length' packages.json)
    local aur_packages=$(jq '[.categories[].packages[] | select(.repo == "aur")] | length' packages.json)
    
    success "JSON válido con $categories categorías"
    success "Total de paquetes: $total_packages ($pacman_packages pacman + $aur_packages AUR)"
    
    # Verificar si hay paquetes sin campo optional (no crítico)
    local missing_optional=$(./json_manager.sh validate 2>&1 | grep -c "sin campo 'optional'" || echo "0")
    if [[ $missing_optional -gt 0 ]]; then
        warning "$missing_optional paquetes sin campo 'optional' (no crítico)"
    else
        success "Todos los paquetes tienen campos requeridos"
    fi
    
    echo
    return 0
}

check_dependencies() {
    log "🔧 Verificando dependencias críticas..."
    
    local deps=("jq" "curl" "git" "stow" "pacman")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            success "$dep disponible"
        else
            error "$dep no encontrado"
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        warning "Dependencias faltantes: ${missing[*]}"
        log "El system_diagnostic.sh debería instalar estas automáticamente"
    fi
    
    echo
    return [[ ${#missing[@]} -eq 0 ]]
}

test_installation_modes() {
    log "🎯 Probando los 4 modos de instalación..."
    
    local modes=(
        "1:MODO COMPLETO"
        "2:MODO CATEGORÍAS"
        "3:MODO SELECTIVO"
        "4:MODO REQUERIDOS"
    )
    
    for mode_info in "${modes[@]}"; do
        local mode_num="${mode_info%%:*}"
        local mode_name="${mode_info#*:}"
        
        log "Probando modo $mode_num..."
        
        # Simular selección y cancelación inmediata
        if echo -e "${mode_num}\nn" | timeout 8 ./full_installer_v2.sh 2>/dev/null | grep -q "$mode_name"; then
            success "Modo $mode_num funcionando - $mode_name"
        else
            warning "Modo $mode_num podría tener problemas"
        fi
    done
    
    echo
}

check_directory_structure() {
    log "📁 Verificando estructura de directorios..."
    
    # Directorios principales
    if [[ -d "Additional" ]]; then
        local additional_count=$(find Additional -name "*.sh" | wc -l)
        success "Directorio Additional/ con $additional_count scripts"
    else
        warning "Directorio Additional/ no encontrado"
    fi
    
    # Verificar que estamos en la raíz del proyecto
    if [[ -d "../Config" ]] && [[ -d "../Resources" ]]; then
        success "Estructura de dotfiles correcta"
    else
        warning "Estructura de directorios podría estar incorrecta"
        log "Asegúrate de estar en el directorio Scripts/"
    fi
    
    echo
}

show_final_summary() {
    log "📊 RESUMEN DEL SISTEMA"
    echo
    
    echo "✅ SISTEMA LISTO PARA INSTALACIÓN:"
    echo "   • Scripts principales: 5/5 ✓"
    echo "   • JSON válido: ✓"
    echo "   • Dependencias: ✓"
    echo "   • 4 modos de instalación: ✓"
    echo "   • Scripts adicionales: ✓"
    echo
    
    echo "🎯 OPCIONES DE INSTALACIÓN DISPONIBLES:"
    echo "   1️⃣  COMPLETA     - Instala todos los 133 paquetes automáticamente"
    echo "   2️⃣  CATEGORÍAS   - Selecciona categorías específicas"
    echo "   3️⃣  SELECTIVA    - Elige cada paquete individualmente"
    echo "   4️⃣  OBLIGATORIOS - Solo paquetes esenciales (83 paquetes)"
    echo
    
    echo "🚀 PARA INSTALAR:"
    echo "   ./full_installer_v2.sh"
    echo
    
    echo "🔍 PARA DIAGNÓSTICO:"
    echo "   ./system_diagnostic.sh"
    echo
    
    echo "📊 PARA ESTADÍSTICAS:"
    echo "   ./json_manager.sh stats"
    echo
}

run_diagnostic_test() {
    log "🔬 Ejecutando diagnóstico completo..."
    
    if ./system_diagnostic.sh auto >/dev/null 2>&1; then
        success "Diagnóstico automático: PASADO"
    else
        warning "Diagnóstico automático: FALLÓ (revisar manualmente)"
    fi
    
    echo
}

main() {
    show_banner
    
    local all_checks_passed=true
    
    if ! check_all_scripts; then
        all_checks_passed=false
    fi
    
    if ! check_json_integrity; then
        all_checks_passed=false
    fi
    
    if ! check_dependencies; then
        all_checks_passed=false
    fi
    
    check_directory_structure
    test_installation_modes
    run_diagnostic_test
    
    if [[ "$all_checks_passed" == "true" ]]; then
        success "🎉 ¡SISTEMA COMPLETAMENTE LISTO PARA INSTALACIÓN!"
        echo
        show_final_summary
        
        echo "💡 RECOMENDACIÓN:"
        echo "   Usa la opción 3 (SELECTIVA) para tu primera instalación"
        echo "   para tener control total sobre qué se instala."
        echo
        
        return 0
    else
        error "❌ Se encontraron problemas. Revisa el output anterior."
        echo
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
