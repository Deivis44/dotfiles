#!/bin/bash

# ==============================================================================
# SYSTEM DIAGNOSTIC - Verificación completa del entorno
# Diagnóstico previo para dotfiles v2.0
# ==============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_YAML="$SCRIPT_DIR/packages.yaml"

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

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    while true; do
        read -p "$prompt [y/N]: " response
        response="${response:-$default}"
        case "${response,,}" in
            y|yes|s|si) return 0 ;;
            n|no) return 1 ;;
            *) echo "Por favor, responde con y/n (yes/no)" ;;
        esac
    done
}

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
    local missing_aur_helpers=()
    
    for manager in "${managers[@]}"; do
        if command -v "$manager" >/dev/null 2>&1; then
            success "$manager disponible: $(which "$manager")"
            ((found++))
        else
            warning "$manager no encontrado"
            if [[ "$manager" != "pacman" ]]; then
                missing_aur_helpers+=("$manager")
            fi
        fi
    done
    
    if [[ $found -eq 0 ]]; then
        error "❌ No se encontró ningún gestor de paquetes Arch"
        return 1
    fi
    
    # Si pacman está pero no hay AUR helpers, instalar yay
    if command -v pacman >/dev/null 2>&1 && ! command -v yay >/dev/null 2>&1 && ! command -v paru >/dev/null 2>&1; then
        warning "No se encontró AUR helper"
        if ask_yes_no "¿Instalar yay (AUR helper) automáticamente?" "y"; then
            log "🔄 Instalando yay..."
            if install_yay_helper; then
                success "✅ yay instalado correctamente"
            else
                warning "⚠️  No se pudo instalar yay automáticamente"
                log "💡 Para instalar manualmente:"
                log "   git clone https://aur.archlinux.org/yay.git"
                log "   cd yay && makepkg -si"
            fi
        else
            log "💡 Para instalar yay manualmente:"
            log "   git clone https://aur.archlinux.org/yay.git"
            log "   cd yay && makepkg -si"
        fi
    fi
    
    echo
}

install_yay_helper() {
    log "🔄 Instalando yay (AUR helper)..."
    
    # Verificar dependencias para compilar yay
    local build_deps=("base-devel" "git")
    local missing_build_deps=()
    
    for dep in "${build_deps[@]}"; do
        if ! pacman -Qq "$dep" >/dev/null 2>&1; then
            missing_build_deps+=("$dep")
        fi
    done
    
    # Instalar dependencias de compilación si faltan
    if [[ ${#missing_build_deps[@]} -gt 0 ]]; then
        log "📦 Instalando dependencias de compilación: ${missing_build_deps[*]}"
        if ! sudo pacman -S --needed --noconfirm "${missing_build_deps[@]}" >/dev/null 2>&1; then
            error "No se pudieron instalar las dependencias de compilación"
            return 1
        fi
    fi
    
    # Crear directorio temporal
    local temp_dir
    temp_dir=$(mktemp -d)
    local original_dir=$(pwd)
    
    # Instalar yay
    {
        cd "$temp_dir"
        if git clone https://aur.archlinux.org/yay.git >/dev/null 2>&1; then
            cd yay
            if makepkg -si --noconfirm >/dev/null 2>&1; then
                cd "$original_dir"
                rm -rf "$temp_dir"
                return 0
            fi
        fi
    }
    
    # Limpiar en caso de error
    cd "$original_dir"
    rm -rf "$temp_dir"
    return 1
}

install_missing_tools() {
    local tools_to_install=("$@")
    local installation_failed=()
    local installation_success=()
    
    log "🔄 Instalando herramientas faltantes: ${tools_to_install[*]}"
    
    # Verificar que tenemos un gestor de paquetes disponible
    if ! command -v pacman >/dev/null 2>&1; then
        error "pacman no disponible - no se pueden instalar herramientas automáticamente"
        return 1
    fi
    
    # Verificar acceso sudo
    if ! sudo -n true 2>/dev/null; then
        warning "Se requiere contraseña sudo para instalar herramientas"
        if ! sudo -v; then
            error "No se pudo obtener acceso sudo"
            return 1
        fi
    fi
    
    # Actualizar base de datos de paquetes
    log "🔄 Actualizando base de datos de paquetes..."
    if ! sudo pacman -Sy --noconfirm >/dev/null 2>&1; then
        warning "No se pudo actualizar la base de datos de pacman"
    fi
    
    # Instalar cada herramienta
    for tool in "${tools_to_install[@]}"; do
        log "📦 Instalando $tool..."
        
        if sudo pacman -S --needed --noconfirm "$tool" >/dev/null 2>&1; then
            success "✅ $tool instalado correctamente"
            installation_success+=("$tool")
            
            # Verificar que ahora está disponible
            if command -v "$tool" >/dev/null 2>&1; then
                success "✅ $tool verificado y funcionando"
            else
                warning "⚠️  $tool instalado pero no disponible en PATH"
            fi
        else
            error "❌ Error al instalar $tool"
            installation_failed+=("$tool")
        fi
    done
    
    # Mostrar resumen
    if [[ ${#installation_success[@]} -gt 0 ]]; then
        success "✅ Instaladas exitosamente: ${installation_success[*]}"
    fi
    
    if [[ ${#installation_failed[@]} -gt 0 ]]; then
        error "❌ No se pudieron instalar: ${installation_failed[*]}"
        log "💡 Intenta instalar manualmente:"
        for tool in "${installation_failed[@]}"; do
            log "   sudo pacman -S $tool"
        done
        return 1
    fi
    
    return 0
}

check_critical_tools() {
    log "🔧 Herramientas críticas"
    
    local tools=(
        "yq:YAML processor"
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
        
        if ask_yes_no "¿Instalar automáticamente las herramientas faltantes?" "y"; then
            log "🔄 Instalando herramientas automáticamente..."
            
            # Intentar instalar herramientas faltantes
            if install_missing_tools "${missing[@]}"; then
                success "✅ Herramientas instaladas correctamente"
                return 0
            else
                warning "❌ No se pudieron instalar algunas herramientas automáticamente"
                log "💡 Para instalar manualmente: sudo pacman -S ${missing[*]}"
                return 1
            fi
        else
            log "💡 Para instalar manualmente: sudo pacman -S ${missing[*]}"
            return 1
        fi
    else
        success "✅ Todas las herramientas críticas están disponibles"
    fi
    
    echo
}

check_dotfiles_structure() {
    log "📁 Estructura de dotfiles"
    
    local required_paths=(
        "$SCRIPT_DIR:Scripts directory"
        "$PACKAGES_YAML:Main packages file"
        "$SCRIPT_DIR/full_installer_v2.sh:Main installer"
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

check_yaml_integrity() {
    log "📄 Integridad del YAML"
    
    if [[ ! -f "$PACKAGES_YAML" ]]; then
        error "packages.yaml no encontrado"
        return 1
    fi
    
    # Verificar sintaxis
    if ! yq '.' "$PACKAGES_YAML" >/dev/null 2>&1; then
        error "YAML con sintaxis inválida"
        echo "   🔍 Error:"
        yq '.' "$PACKAGES_YAML" 2>&1 | head -5
        return 1
    fi
    
    success "Sintaxis YAML válida"
    
    # Verificar estructura
    local categories_count=$(yq '.categories | length' "$PACKAGES_YAML" 2>/dev/null || echo "0")
    local total_packages=$(yq '[.categories[].packages | length] | add' "$PACKAGES_YAML" 2>/dev/null || echo "0")
    
    success "Categorías: $categories_count"
    success "Paquetes totales: $total_packages"
    
    # Verificar que podemos leer categorías
    if yq '.categories[].id' "$PACKAGES_YAML" 2>/dev/null | head -3 >/dev/null; then
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
    local scripts=("full_installer_v2.sh" "stow-links.sh")
    
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
    
    # Test 1: yq parsing
    if yq '.categories[0].id' "$PACKAGES_YAML" >/dev/null 2>&1; then
        success "yq parsing - OK"
    else
        error "yq parsing - FAIL"
    fi
    
    # Test 2: Array capture simulation
    local test_categories=()
    while IFS= read -r category_id; do
        if [[ -n "$category_id" ]] && [[ "$category_id" != "null" ]]; then
            test_categories+=("$category_id")
        fi
    done < <(yq '.categories[].id' "$PACKAGES_YAML" 2>/dev/null | head -3)
    
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
        for tool in yq curl git stow; do
            if command -v "$tool" >/dev/null 2>&1; then
                echo "  ✓ $tool: $(which "$tool")"
            else
                echo "  ✗ $tool: MISSING"
            fi
        done
        
        echo
        echo "YAML STATUS:"
        if [[ -f "$PACKAGES_YAML" ]]; then
            echo "  ✓ File exists: $PACKAGES_YAML"
            if yq '.' "$PACKAGES_YAML" >/dev/null 2>&1; then
                echo "  ✓ Valid YAML syntax"
                echo "  Categories: $(yq '.categories | length' "$PACKAGES_YAML")"
                echo "  Packages: $(yq '[.categories[].packages | length] | add' "$PACKAGES_YAML")"
            else
                echo "  ✗ Invalid YAML syntax"
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
    echo "   🔍 Para validar YAML:"
    echo "      yq '.' packages.yaml"
    echo
    echo "   📦 Para ver estadísticas:"
    echo "      yq '.categories | length' packages.yaml"
    echo "      yq '[.categories[].packages | length] | add' packages.yaml"
    echo
}

main() {
    local run_mode="${1:-interactive}"
    
    show_banner
    
    # Configurar modo automático si se solicita
    if [[ "$run_mode" == "auto" ]]; then
        log "🤖 Modo automático: instalando herramientas faltantes sin preguntar"
        # Redefinir ask_yes_no para que siempre devuelva sí en modo auto
        ask_yes_no() { return 0; }
    fi
    
    local exit_code=0
    
    check_system_info
    check_package_managers || exit_code=1
    check_critical_tools || exit_code=1
    check_dotfiles_structure || exit_code=1
    check_yaml_integrity || exit_code=1
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
    # Mostrar ayuda si se solicita
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        echo "🔍 System Diagnostic v2.0"
        echo
        echo "USAGE: $0 [mode]"
        echo
        echo "MODES:"
        echo "  interactive  Preguntar antes de instalar (default)"
        echo "  auto         Instalar automáticamente sin preguntar"
        echo
        echo "EXAMPLES:"
        echo "  $0               # Modo interactivo"
        echo "  $0 interactive   # Modo interactivo explícito"
        echo "  $0 auto          # Instalación automática"
        exit 0
    fi
    
    main "$@"
fi
