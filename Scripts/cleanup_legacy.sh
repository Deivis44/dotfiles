#!/bin/bash

# ==============================================================================
# SCRIPT DE LIMPIEZA AUTOMÁTICA - DOTFILES v2.0
# Elimina scripts legacy y reorganiza el sistema
# ==============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Funciones de utilidad
info() { echo -e "\033[32m[INFO]\033[0m $*"; }
warning() { echo -e "\033[33m[WARNING]\033[0m $*"; }
error() { echo -e "\033[31m[ERROR]\033[0m $*"; }

show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════╗
║                    🧹 DOTFILES CLEANUP v2.0                         ║
║                  Eliminando scripts legacy                           ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo
}

ask_confirmation() {
    local prompt="$1"
    local response
    
    while true; do
        read -p "$prompt [y/N]: " response
        case "${response,,}" in
            y|yes) return 0 ;;
            n|no|"") return 1 ;;
            *) echo "Por favor, responde con y/n" ;;
        esac
    done
}

cleanup_legacy_scripts() {
    info "🔍 Detectando scripts legacy para eliminar..."
    
    local legacy_scripts=(
        "install-packages.sh"
        "package_installer.sh" 
        "installer_json_native.sh"
        "Full_Install.sh"
        "migrate_to_json.sh"
        "full_installer_v2.sh.backup"
    )
    
    local found_scripts=()
    
    for script in "${legacy_scripts[@]}"; do
        if [[ -f "$SCRIPT_DIR/$script" ]]; then
            found_scripts+=("$script")
        fi
    done
    
    if [[ ${#found_scripts[@]} -eq 0 ]]; then
        info "✅ No se encontraron scripts legacy para eliminar"
        return 0
    fi
    
    echo "📋 Scripts legacy encontrados:"
    for script in "${found_scripts[@]}"; do
        echo "   - $script"
    done
    echo
    
    if ask_confirmation "¿Eliminar estos scripts legacy?"; then
        for script in "${found_scripts[@]}"; do
            rm -f "$SCRIPT_DIR/$script"
            info "🗑️  Eliminado: $script"
        done
        info "✅ Limpieza de scripts legacy completada"
    else
        info "⏭️  Limpieza cancelada por el usuario"
    fi
}

verify_main_scripts() {
    info "🔍 Verificando scripts principales..."
    
    local main_scripts=(
        "full_installer_v2.sh"
        "packages.json"
        "json_manager.sh"
        "stow-links.sh"
        "install_extra_packs.sh"
    )
    
    local missing_scripts=()
    
    for script in "${main_scripts[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$script" ]]; then
            missing_scripts+=("$script")
        fi
    done
    
    if [[ ${#missing_scripts[@]} -eq 0 ]]; then
        info "✅ Todos los scripts principales están presentes"
    else
        warning "⚠️  Scripts principales faltantes:"
        for script in "${missing_scripts[@]}"; do
            echo "   - $script"
        done
    fi
}

show_final_structure() {
    info "📁 Estructura final del directorio Scripts:"
    echo
    
    # Mostrar estructura actualizada
    if command -v tree >/dev/null 2>&1; then
        tree "$SCRIPT_DIR" -I "*.log|*.backup"
    else
        ls -la "$SCRIPT_DIR"
    fi
}

show_usage_summary() {
    echo
    info "🚀 Resumen de uso del nuevo sistema:"
    echo
    echo "1️⃣  INSTALACIÓN COMPLETA:"
    echo "   ./full_installer_v2.sh"
    echo
    echo "2️⃣  GESTIÓN DE JSON:"
    echo "   ./json_manager.sh validate"
    echo "   ./json_manager.sh stats"
    echo
    echo "3️⃣  TESTING:"
    echo "   ./test_system.sh"
    echo
    echo "📖 Para más detalles: cat CLEANUP_GUIDE.md"
    echo
}

main() {
    show_banner
    
    info "Iniciando limpieza de dotfiles v2.0..."
    echo
    
    # Verificar que estamos en el directorio correcto
    if [[ ! -f "$SCRIPT_DIR/packages.json" ]]; then
        error "❌ packages.json no encontrado. Ejecuta desde el directorio Scripts/"
        exit 1
    fi
    
    # Ejecutar limpieza
    cleanup_legacy_scripts
    echo
    
    # Verificar scripts principales
    verify_main_scripts
    echo
    
    # Mostrar estructura final
    show_final_structure
    echo
    
    # Mostrar resumen de uso
    show_usage_summary
    
    info "🎉 ¡Limpieza completada! Tu sistema dotfiles v2.0 está listo."
}

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
