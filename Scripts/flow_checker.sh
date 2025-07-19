#!/bin/bash

# ==============================================================================
# FLOW CHECKER - Verificador del flujo completo de dotfiles v2.0
# ==============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colores
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warning() { echo -e "${YELLOW}[!]${NC} $*"; }

show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════╗
║                   📋 DOTFILES FLOW CHECKER v2.0                     ║
║                    Verificación del flujo completo                   ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo
}

check_core_files() {
    info "🔍 Verificando archivos principales..."
    
    local core_files=(
        "packages.json:Base de datos JSON única"
        "full_installer_v2.sh:Instalador principal unificado"
        "json_manager.sh:Gestión y validación del JSON"
        "system_diagnostic.sh:Diagnóstico del sistema"
        "stow-links.sh:Gestión de enlaces simbólicos"
        "install_extra_packs.sh:Paquetes adicionales (TPM, NvChad, etc.)"
    )
    
    for file_info in "${core_files[@]}"; do
        local file="${file_info%%:*}"
        local desc="${file_info#*:}"
        
        if [[ -f "$SCRIPT_DIR/$file" ]]; then
            local size=$(stat -c%s "$SCRIPT_DIR/$file")
            success "$file (${size} bytes) - $desc"
        else
            warning "$file - NO ENCONTRADO - $desc"
        fi
    done
    echo
}

check_additional_scripts() {
    info "🔧 Verificando scripts adicionales..."
    
    if [[ -d "$SCRIPT_DIR/Additional" ]]; then
        local additional_scripts=(
            "Pacman.sh"
            "MineGRUB.sh" 
            "fastfetch.sh"
            "setup-bluetooth.sh"
        )
        
        for script in "${additional_scripts[@]}"; do
            if [[ -f "$SCRIPT_DIR/Additional/$script" ]]; then
                success "Additional/$script - Disponible"
            else
                warning "Additional/$script - No encontrado"
            fi
        done
    else
        warning "Directorio Additional/ no encontrado"
    fi
    echo
}

check_utility_scripts() {
    info "🛠️  Verificando scripts de utilidad..."
    
    local utility_scripts=(
        "cleanup_legacy.sh:Limpieza de archivos legacy"
        "test_system.sh:Tests del sistema"
        "rm-links.sh:Eliminación de enlaces"
    )
    
    for script_info in "${utility_scripts[@]}"; do
        local script="${script_info%%:*}"
        local desc="${script_info#*:}"
        
        if [[ -f "$SCRIPT_DIR/$script" ]]; then
            success "$script - $desc"
        else
            warning "$script - No encontrado - $desc"
        fi
    done
    echo
}

check_unwanted_files() {
    info "🗑️  Buscando archivos innecesarios..."
    
    local unwanted_patterns=(
        "*.backup"
        "*.old" 
        "*~"
        "*.tmp"
        "debug_*"
        "vm_debug*"
        "*_test.sh"
        "packages2.json"
        "packages_backup.json"
        "install-packages.sh"
        "package_installer.sh"
        "installer_json_native.sh"
        "Full_Install.sh"
        "migrate_to_json.sh"
    )
    
    local found_unwanted=()
    
    for pattern in "${unwanted_patterns[@]}"; do
        while IFS= read -r -d '' file; do
            found_unwanted+=("$(basename "$file")")
        done < <(find "$SCRIPT_DIR" -maxdepth 1 -name "$pattern" -print0 2>/dev/null || true)
    done
    
    if [[ ${#found_unwanted[@]} -eq 0 ]]; then
        success "✅ No se encontraron archivos innecesarios"
    else
        warning "⚠️  Archivos innecesarios encontrados:"
        for file in "${found_unwanted[@]}"; do
            echo "   - $file"
        done
        echo
        echo "   💡 Para eliminar: rm -f ${found_unwanted[*]}"
    fi
    echo
}

verify_workflow() {
    info "🔄 Verificando flujo de trabajo..."
    
    echo "   📋 FLUJO PRINCIPAL:"
    echo "   1️⃣  ./system_diagnostic.sh     ← Diagnóstico previo"
    echo "   2️⃣  ./full_installer_v2.sh     ← Instalación completa (con pre-check automático)"
    echo
    echo "   📋 FLUJO ALTERNATIVO - JSON:"
    echo "   1️⃣  ./json_manager.sh validate ← Validar JSON"
    echo "   2️⃣  ./json_manager.sh stats    ← Ver estadísticas"
    echo "   3️⃣  ./full_installer_v2.sh     ← Instalación"
    echo
    echo "   📋 FLUJO ALTERNATIVO - MODULAR:"
    echo "   1️⃣  ./system_diagnostic.sh     ← Diagnóstico"
    echo "   2️⃣  ./full_installer_v2.sh     ← Solo paquetes"
    echo "   3️⃣  ./install_extra_packs.sh   ← Paquetes adicionales"
    echo "   4️⃣  ./stow-links.sh           ← Enlaces simbólicos"
    echo
    echo "   📋 UTILIDADES:"
    echo "   🧹 ./cleanup_legacy.sh        ← Limpiar archivos legacy"
    echo "   🧪 ./test_system.sh           ← Tests adicionales"
    echo "   🗑️  ./rm-links.sh             ← Eliminar enlaces"
    echo
}

show_file_structure() {
    info "📁 Estructura actual:"
    echo
    
    if command -v tree >/dev/null 2>&1; then
        tree "$SCRIPT_DIR" -I "*.log|*.cache" --dirsfirst
    else
        ls -la "$SCRIPT_DIR"
    fi
    echo
}

verify_json_integrity() {
    info "📄 Verificando integridad del JSON principal..."
    
    local json_file="$SCRIPT_DIR/packages.json"
    
    if [[ -f "$json_file" ]]; then
        if command -v jq >/dev/null 2>&1; then
            if jq empty "$json_file" 2>/dev/null; then
                local categories=$(jq '.categories | length' "$json_file")
                local packages=$(jq '[.categories[].packages | length] | add' "$json_file")
                success "JSON válido: $categories categorías, $packages paquetes"
            else
                warning "JSON con errores de sintaxis"
            fi
        else
            warning "jq no disponible, no se puede validar JSON"
        fi
    else
        warning "packages.json no encontrado"
    fi
    echo
}

main() {
    show_banner
    
    check_core_files
    check_additional_scripts
    check_utility_scripts
    check_unwanted_files
    verify_json_integrity
    verify_workflow
    show_file_structure
    
    success "🎉 Verificación del flujo completada"
}

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
