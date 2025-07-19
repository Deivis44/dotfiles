#!/bin/bash

# ==============================================================================
# SYSTEM DIAGNOSTIC - Verificación completa del entorno
# Diagnóstico previo para dotfiles v2.0
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

log() { echo -e "${BLUE}[DIAG]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warning() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; }

show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════╗
║                   🔍 SYSTEM DIAGNOSTIC v2.0                         ║
║              Verificación completa del entorno                       ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo
}

check_system_info() {
    log "📋 Información del sistema"
    echo "   🖥️  SO: $(uname -s) $(uname -r)"
    echo "   🏗️  Arquitectura: $(uname -m)"
    echo "   👤 Usuario: $(whoami)"
    echo "   🏠 HOME: $HOME"
    echo "   📁 PWD: $(pwd)"
    echo "   🐚 Shell: ${SHELL:-N/A}"
    echo "   📄 Bash version: ${BASH_VERSION:-N/A}"
    echo
}

check_package_managers() {
    log "📦 Gestores de paquetes"
    
    local managers=("pacman" "yay" "paru")
    local found=0
    
    for manager in "${managers[@]}"; do
        if command -v "$manager" >/dev/null 2>&1; then
            success "$manager disponible: $(which "$manager")"
            ((found++))
        else
            warning "$manager no encontrado"
        fi
    done
    
    if [[ $found -eq 0 ]]; then
        error "❌ No se encontró ningún gestor de paquetes Arch"
        return 1
    fi
    
    echo
}

check_critical_tools() {
    log "🔧 Herramientas críticas"
    
    local tools=(
        "jq:JSON processor"
        "curl:HTTP client"
        "git:Version control"
        "stow:Symlink manager"
        "sudo:Privilege escalation"
        "bash:Shell interpreter"
    )
    
    local missing=()
    local available=()
    
    for tool_info in "${tools[@]}"; do
        local tool="${tool_info%%:*}"
        local desc="${tool_info#*:}"
        
        if command -v "$tool" >/dev/null 2>&1; then
            local version=$(${tool} --version 2>/dev/null | head -1 || echo "Version N/A")
            success "$tool ($desc) - $version"
            available+=("$tool")
        else
            error "$tool ($desc) - NO ENCONTRADO"
            missing+=("$tool")
        fi
    done
    
    echo
    if [[ ${#missing[@]} -gt 0 ]]; then
        warning "⚠️  Herramientas faltantes: ${missing[*]}"
        log "💡 Para instalar: sudo pacman -S ${missing[*]}"
        return 1
    else
        success "✅ Todas las herramientas críticas están disponibles"
    fi
    
    echo
}

check_dotfiles_structure() {
    log "📁 Estructura de dotfiles"
    
    local required_paths=(
        "$SCRIPT_DIR:Scripts directory"
        "$PACKAGES_JSON:Main packages file"
        "$SCRIPT_DIR/full_installer_v2.sh:Main installer"
        "$SCRIPT_DIR/json_manager.sh:JSON manager"
        "$SCRIPT_DIR/stow-links.sh:Symlink manager"
        "$SCRIPT_DIR/install_extra_packs.sh:Extra packages"
        "$SCRIPT_DIR/Additional:Additional scripts"
    )
    
    local missing_paths=()
    
    for path_info in "${required_paths[@]}"; do
        local path="${path_info%%:*}"
        local desc="${path_info#*:}"
        
        if [[ -e "$path" ]]; then
            if [[ -f "$path" ]]; then
                local size=$(stat -c%s "$path" 2>/dev/null || echo "0")
                success "$desc - $(basename "$path") (${size} bytes)"
            else
                success "$desc - $(basename "$path") (directory)"
            fi
        else
            error "$desc - NO ENCONTRADO: $path"
            missing_paths+=("$path")
        fi
    done
    
    echo
    if [[ ${#missing_paths[@]} -gt 0 ]]; then
        warning "⚠️  Archivos/directorios faltantes: ${#missing_paths[@]}"
        return 1
    else
        success "✅ Estructura de dotfiles completa"
    fi
    
    echo
}

check_json_integrity() {
    log "📄 Integridad del JSON"
    
    if [[ ! -f "$PACKAGES_JSON" ]]; then
        error "packages.json no encontrado"
        return 1
    fi
    
    # Verificar sintaxis
    if ! jq empty "$PACKAGES_JSON" 2>/dev/null; then
        error "JSON con sintaxis inválida"
        echo "   🔍 Error:"
        jq . "$PACKAGES_JSON" 2>&1 | head -5
        return 1
    fi
    
    success "Sintaxis JSON válida"
    
    # Verificar estructura
    local categories_count=$(jq '.categories | length' "$PACKAGES_JSON" 2>/dev/null || echo "0")
    local total_packages=$(jq '[.categories[].packages | length] | add' "$PACKAGES_JSON" 2>/dev/null || echo "0")
    
    success "Categorías: $categories_count"
    success "Paquetes totales: $total_packages"
    
    # Verificar que podemos leer categorías
    if jq -r '.categories[].id' "$PACKAGES_JSON" 2>/dev/null | head -3 >/dev/null; then
        success "Lectura de categorías funcional"
    else
        error "No se pueden leer las categorías"
        return 1
    fi
    
    echo
}

check_permissions() {
    log "🔐 Permisos y accesos"
    
    # Verificar permisos de scripts
    local scripts=("full_installer_v2.sh" "json_manager.sh" "stow-links.sh")
    
    for script in "${scripts[@]}"; do
        local script_path="$SCRIPT_DIR/$script"
        if [[ -f "$script_path" ]]; then
            if [[ -x "$script_path" ]]; then
                success "$script - ejecutable"
            else
                warning "$script - no ejecutable"
                log "   💡 Ejecuta: chmod +x $script_path"
            fi
        fi
    done
    
    # Verificar acceso sudo
    if timeout 1 sudo -n true 2>/dev/null; then
        success "sudo - acceso sin contraseña"
    else
        warning "sudo - requerirá contraseña durante la instalación"
    fi
    
    echo
}

run_functional_tests() {
    log "🧪 Tests funcionales"
    
    # Test 1: jq parsing
    if jq -r '.categories[0].id' "$PACKAGES_JSON" >/dev/null 2>&1; then
        success "jq parsing - OK"
    else
        error "jq parsing - FAIL"
    fi
    
    # Test 2: Array capture simulation
    local test_categories=()
    while IFS= read -r category_id; do
        if [[ -n "$category_id" ]] && [[ "$category_id" != "null" ]]; then
            test_categories+=("$category_id")
        fi
    done < <(jq -r '.categories[].id' "$PACKAGES_JSON" 2>/dev/null | head -3)
    
    if [[ ${#test_categories[@]} -gt 0 ]]; then
        success "Array capture - OK (${#test_categories[@]} items)"
    else
        error "Array capture - FAIL"
    fi
    
    # Test 3: Internet connectivity
    if curl -s --connect-timeout 5 https://archlinux.org >/dev/null 2>&1; then
        success "Internet connectivity - OK"
    else
        warning "Internet connectivity - LIMITED"
    fi
    
    echo
}

generate_report() {
    log "📊 Generando reporte"
    
    local report_file="$HOME/.cache/dotfiles_diagnostic_$(date +%Y%m%d_%H%M%S).log"
    mkdir -p "$(dirname "$report_file")"
    
    {
        echo "DOTFILES DIAGNOSTIC REPORT"
        echo "=========================="
        echo "Date: $(date)"
        echo "User: $(whoami)"
        echo "System: $(uname -a)"
        echo
        
        echo "CRITICAL TOOLS:"
        for tool in jq curl git stow; do
            if command -v "$tool" >/dev/null 2>&1; then
                echo "  ✓ $tool: $(which "$tool")"
            else
                echo "  ✗ $tool: MISSING"
            fi
        done
        
        echo
        echo "JSON STATUS:"
        if [[ -f "$PACKAGES_JSON" ]]; then
            echo "  ✓ File exists: $PACKAGES_JSON"
            if jq empty "$PACKAGES_JSON" 2>/dev/null; then
                echo "  ✓ Valid JSON syntax"
                echo "  Categories: $(jq '.categories | length' "$PACKAGES_JSON")"
                echo "  Packages: $(jq '[.categories[].packages | length] | add' "$PACKAGES_JSON")"
            else
                echo "  ✗ Invalid JSON syntax"
            fi
        else
            echo "  ✗ File not found"
        fi
        
    } > "$report_file"
    
    success "Reporte guardado: $report_file"
    echo
}

show_recommendations() {
    log "💡 Recomendaciones"
    
    echo "   🚀 Para instalación completa:"
    echo "      ./full_installer_v2.sh"
    echo
    echo "   🔍 Para validar JSON:"
    echo "      ./json_manager.sh validate"
    echo
    echo "   🧪 Para tests adicionales:"
    echo "      ./test_system.sh"
    echo
    echo "   📋 Para ver estadísticas:"
    echo "      ./json_manager.sh stats"
    echo
}

main() {
    show_banner
    
    local exit_code=0
    
    check_system_info
    check_package_managers || exit_code=1
    check_critical_tools || exit_code=1
    check_dotfiles_structure || exit_code=1
    check_json_integrity || exit_code=1
    check_permissions
    run_functional_tests
    
    generate_report
    show_recommendations
    
    if [[ $exit_code -eq 0 ]]; then
        success "🎉 ¡Sistema listo para dotfiles v2.0!"
    else
        warning "⚠️  Se encontraron algunos problemas. Revisa el output anterior."
    fi
    
    return $exit_code
}

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
