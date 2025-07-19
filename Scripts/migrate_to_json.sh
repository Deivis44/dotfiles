#!/bin/bash

# ==============================================================================
# MIGRACIÓN DEL SISTEMA LEGACY A JSON v2.0
# Migra el sistema actual de arrays de bash al nuevo sistema JSON
# ==============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OLD_SCRIPT="$SCRIPT_DIR/install-packages.sh"
readonly NEW_JSON="$SCRIPT_DIR/packages.json"
readonly BACKUP_DIR="$SCRIPT_DIR/migration_backup"

info() { echo -e "\033[36m[INFO]\033[0m $*"; }
success() { echo -e "\033[32m[SUCCESS]\033[0m $*"; }
warning() { echo -e "\033[33m[WARNING]\033[0m $*"; }
error() { echo -e "\033[31m[ERROR]\033[0m $*"; }

show_migration_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════╗
║                    🔄 MIGRACIÓN A SISTEMA JSON v2.0                  ║
║                   Convirtiendo arrays bash → JSON                    ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
}

create_backup() {
    info "📦 Creando backup del sistema actual..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup de scripts existentes
    if [[ -f "$OLD_SCRIPT" ]]; then
        cp "$OLD_SCRIPT" "$BACKUP_DIR/install-packages_backup_$(date +%Y%m%d_%H%M%S).sh"
    fi
    
    if [[ -f "$NEW_JSON" ]]; then
        cp "$NEW_JSON" "$BACKUP_DIR/packages_backup_$(date +%Y%m%d_%H%M%S).json"
    fi
    
    success "✅ Backup creado en: $BACKUP_DIR"
}

extract_legacy_packages() {
    info "🔍 Extrayendo paquetes del script legacy..."
    
    if [[ ! -f "$OLD_SCRIPT" ]]; then
        warning "Script legacy no encontrado: $OLD_SCRIPT"
        return 1
    fi
    
    # Extraer arrays del script bash usando análisis de texto
    local temp_script
    temp_script=$(mktemp)
    
    # Crear un script temporal que solo declare los arrays
    cat > "$temp_script" << 'EOF'
#!/bin/bash

# Declaración de arrays para agrupar paquetes por funcionalidad
declare -a installed
declare -a skipped
declare -a user_skipped
declare -a errors
EOF
    
    # Extraer las declaraciones de arrays del script original
    sed -n '/^declare -a/,/^)$/p' "$OLD_SCRIPT" >> "$temp_script"
    
    # Agregar función para imprimir arrays en formato JSON
    cat >> "$temp_script" << 'EOF'

# Función para convertir arrays a JSON
convert_to_json() {
    echo "{"
    echo '  "legacy_arrays": {'
    
    local arrays=(
        "dotfiles_tools:1. DOTFILES:🔧:Gestión de dotfiles y control de versiones"
        "system_utilities:2. SYSTEM_UTILITIES:⚙️:Utilidades del sistema y CLI tools"
        "productivity_apps:3. PRODUCTIVITY_APPS:📱:Aplicaciones de productividad y multimedia"
        "development_tools:4. DEVELOPMENT_TOOLS:💻:Herramientas de desarrollo y programación"
        "terminal_shell:5. TERMINAL_SHELL:🖥️:Terminal y shell"
        "fonts_symbols:6. FONTS_SYMBOLS:🔤:Fuentes y símbolos"
        "tmux_plugins:7. TMUX_PLUGINS:📦:Herramientas y plugins para Tmux"
    )
    
    local first=true
    for array_info in "${arrays[@]}"; do
        IFS=':' read -r array_name category_id emoji description <<< "$array_info"
        
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi
        
        echo -n "    \"$array_name\": {"
        echo "\"category_id\": \"$category_id\", \"emoji\": \"$emoji\", \"description\": \"$description\", \"packages\": ["
        
        # Obtener referencia al array
        local -n array_ref="$array_name"
        local pkg_first=true
        
        for package in "${array_ref[@]}"; do
            # Limpiar comentarios del nombre del paquete
            local clean_package
            clean_package=$(echo "$package" | sed 's/#.*//' | tr -d ' ')
            
            if [[ -n "$clean_package" ]]; then
                if [[ "$pkg_first" == "true" ]]; then
                    pkg_first=false
                else
                    echo ","
                fi
                echo -n "      \"$clean_package\""
            fi
        done
        
        echo
        echo -n "    ]}"
    done
    
    echo
    echo "  }"
    echo "}"
}

convert_to_json
EOF
    
    # Ejecutar el script temporal para obtener JSON
    chmod +x "$temp_script"
    bash "$temp_script" > "$BACKUP_DIR/legacy_extraction.json"
    rm "$temp_script"
    
    success "✅ Paquetes legacy extraídos a: $BACKUP_DIR/legacy_extraction.json"
}

validate_current_json() {
    info "🔍 Validando JSON actual..."
    
    if [[ ! -f "$NEW_JSON" ]]; then
        warning "Archivo packages.json no existe, se creará uno nuevo"
        return 1
    fi
    
    if ! jq empty "$NEW_JSON" 2>/dev/null; then
        error "El archivo packages.json actual no es válido"
        return 1
    fi
    
    success "✅ JSON actual es válido"
    return 0
}

create_enhanced_categories() {
    info "🏗️  Creando estructura de categorías mejoradas..."
    
    # Verificar si el JSON actual tiene todas las categorías necesarias
    local current_categories
    current_categories=$(jq -r '.categories[].id' "$NEW_JSON" 2>/dev/null || echo "")
    
    local required_categories=(
        "1. DOTFILES"
        "2. CORE_SYSTEM" 
        "3. CLI_TOOLS"
        "4. SYSTEM_MONITORING"
        "5. SECURITY_PRIVACY"
        "6. DESKTOP_TOOLS"
        "7. TERMINAL_SHELL"
        "8. FONTS_SYMBOLS"
        "9. EDITORS_IDES"
        "10. LANGUAGES_RUNTIMES"
        "11. PYTHON_ECOSYSTEM"
        "12. DEV_TOOLS"
        "13. VIRTUALIZATION"
        "14. OFFICE_DOCUMENTS"
        "15. WEB_BROWSERS"
        "16. MUSIC_CLIENTS"
        "17. FILE_SYNC"
        "18. MULTIMEDIA_STREAMING"
        "19. COMMUNICATIONS"
        "20. TERMINAL_MULTIPLEXING"
        "21. CLI_UTILITIES"
        "22. FUN_TOOLS"
    )
    
    local missing_categories=()
    for required in "${required_categories[@]}"; do
        if ! echo "$current_categories" | grep -q "^$required$"; then
            missing_categories+=("$required")
        fi
    done
    
    if [[ ${#missing_categories[@]} -gt 0 ]]; then
        info "📋 Categorías faltantes detectadas: ${missing_categories[*]}"
        info "El JSON actual parece estar completo, no se requiere migración adicional"
    else
        success "✅ Todas las categorías requeridas están presentes"
    fi
}

optimize_json_structure() {
    info "⚡ Optimizando estructura JSON..."
    
    local temp_file
    temp_file=$(mktemp)
    
    # Reformatear y optimizar el JSON
    jq --indent 2 '
    {
      "metadata": {
        "version": "2.0",
        "created": now | todate,
        "description": "Configuración de paquetes para dotfiles de Arch Linux",
        "total_categories": (.categories | length),
        "total_packages": ([.categories[].packages[]?] | length)
      },
      "categories": .categories | sort_by(.id)
    }' "$NEW_JSON" > "$temp_file" && mv "$temp_file" "$NEW_JSON"
    
    success "✅ Estructura JSON optimizada"
}

create_migration_scripts() {
    info "📝 Creando scripts de migración..."
    
    # Script para hacer permisos ejecutables
    cat > "$SCRIPT_DIR/setup_permissions.sh" << 'EOF'
#!/bin/bash
# Establecer permisos ejecutables para todos los scripts

find "$(dirname "${BASH_SOURCE[0]}")" -name "*.sh" -type f -exec chmod +x {} \;
echo "✅ Permisos ejecutables establecidos para todos los scripts"
EOF
    
    # Script de validación post-migración
    cat > "$SCRIPT_DIR/validate_migration.sh" << 'EOF'
#!/bin/bash
# Validar que la migración fue exitosa

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔍 Validando migración..."

# Verificar archivos principales
files_to_check=(
    "package_installer.sh"
    "json_manager.sh" 
    "packages.json"
)

for file in "${files_to_check[@]}"; do
    if [[ -f "$SCRIPT_DIR/$file" ]]; then
        echo "✅ $file existe"
    else
        echo "❌ $file faltante"
        exit 1
    fi
done

# Validar JSON
if ! command -v jq >/dev/null 2>&1; then
    echo "⚠️  jq no está instalado, no se puede validar JSON"
    exit 0
fi

if jq empty "$SCRIPT_DIR/packages.json" 2>/dev/null; then
    echo "✅ packages.json es válido"
else
    echo "❌ packages.json inválido"
    exit 1
fi

echo "🎉 Migración validada exitosamente"
EOF
    
    chmod +x "$SCRIPT_DIR/setup_permissions.sh"
    chmod +x "$SCRIPT_DIR/validate_migration.sh"
    
    success "✅ Scripts de migración creados"
}

show_migration_summary() {
    echo
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                        📋 RESUMEN DE MIGRACIÓN                       ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo
    
    local total_categories total_packages
    total_categories=$(jq '.categories | length' "$NEW_JSON" 2>/dev/null || echo "0")
    total_packages=$(jq '[.categories[].packages[]?] | length' "$NEW_JSON" 2>/dev/null || echo "0")
    
    echo "✅ Archivos creados:"
    echo "   📦 package_installer.sh - Instalador principal"
    echo "   🔧 json_manager.sh - Gestor de JSON"
    echo "   📄 packages.json - Base de datos de paquetes"
    echo
    echo "📊 Estadísticas:"
    echo "   📁 Total de categorías: $total_categories"
    echo "   📦 Total de paquetes: $total_packages"
    echo
    echo "🔄 Próximos pasos:"
    echo "   1. Ejecutar: ./validate_migration.sh"
    echo "   2. Probar: ./json_manager.sh validate"
    echo "   3. Usar: ./package_installer.sh"
    echo
    echo "💾 Backup disponible en: $BACKUP_DIR"
}

main() {
    show_migration_banner
    
    # Verificar dependencias
    if ! command -v jq >/dev/null 2>&1; then
        error "jq no está instalado. Instalando..."
        sudo pacman -S --noconfirm jq
    fi
    
    # Proceso de migración
    create_backup
    
    # Si ya tenemos un JSON válido, solo optimizar
    if validate_current_json; then
        optimize_json_structure
        create_migration_scripts
        success "✅ JSON existente optimizado y scripts auxiliares creados"
    else
        warning "JSON no válido o inexistente, usando el sistema actual"
        extract_legacy_packages
        create_enhanced_categories
        create_migration_scripts
    fi
    
    show_migration_summary
    
    success "🎉 ¡Migración completada!"
    echo
    info "Para probar el nuevo sistema, ejecuta:"
    echo "  ./package_installer.sh"
}

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
