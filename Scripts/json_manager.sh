#!/bin/bash

# ==============================================================================
# DOTFILES JSON MANAGER
# Utilidad para gestionar el archivo packages.json
# ==============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"

# ==============================================================================
# FUNCIONES DE UTILIDAD
# ==============================================================================

info() { echo -e "\033[36m[INFO]\033[0m $*"; }
success() { echo -e "\033[32m[SUCCESS]\033[0m $*"; }
warning() { echo -e "\033[33m[WARNING]\033[0m $*"; }
error() { echo -e "\033[31m[ERROR]\033[0m $*"; }

show_help() {
    cat << 'EOF'
🔧 Dotfiles JSON Manager

USAGE:
    ./json_manager.sh <command> [options]

COMMANDS:
    validate                    Validar la sintaxis del JSON
    list-categories            Listar todas las categorías
    list-packages [category]   Listar paquetes (opcionalmente de una categoría)
    add-package                Agregar un nuevo paquete interactivamente
    remove-package <name>      Eliminar un paquete
    stats                      Mostrar estadísticas del archivo
    backup                     Crear backup del archivo JSON
    restore <backup_file>      Restaurar desde un backup

EXAMPLES:
    ./json_manager.sh validate
    ./json_manager.sh list-packages "1. DOTFILES"
    ./json_manager.sh add-package
    ./json_manager.sh stats
EOF
}

# ==============================================================================
# VALIDACIÓN
# ==============================================================================

validate_json() {
    info "Validando archivo packages.json..."
    
    if [[ ! -f "$PACKAGES_JSON" ]]; then
        error "Archivo packages.json no encontrado"
        return 1
    fi
    
    if ! jq empty "$PACKAGES_JSON" 2>/dev/null; then
        error "El archivo JSON no es válido"
        return 1
    fi
    
    # Validaciones específicas
    local errors=0
    
    # Verificar estructura básica
    if ! jq -e '.categories' "$PACKAGES_JSON" >/dev/null; then
        error "Falta la propiedad 'categories'"
        ((errors++))
    fi
    
    # Verificar cada categoría
    local categories
    categories=$(jq -r '.categories[] | @base64' "$PACKAGES_JSON")
    
    while IFS= read -r category_b64; do
        local category
        category=$(echo "$category_b64" | base64 --decode)
        
        local id emoji description
        id=$(echo "$category" | jq -r '.id // "missing"')
        emoji=$(echo "$category" | jq -r '.emoji // "missing"')
        description=$(echo "$category" | jq -r '.description // "missing"')
        
        if [[ "$id" == "missing" ]]; then
            error "Categoría sin ID encontrada"
            ((errors++))
        fi
        
        if [[ "$emoji" == "missing" ]]; then
            warning "Categoría $id sin emoji"
        fi
        
        if [[ "$description" == "missing" ]]; then
            warning "Categoría $id sin descripción"
        fi
        
        # Verificar paquetes en la categoría
        local packages
        packages=$(echo "$category" | jq -r '.packages[]? | @base64')
        
        while IFS= read -r package_b64; do
            if [[ -n "$package_b64" ]]; then
                local package
                package=$(echo "$package_b64" | base64 --decode)
                
                local name repo optional
                name=$(echo "$package" | jq -r '.name // "missing"')
                repo=$(echo "$package" | jq -r '.repo // "missing"')
                optional=$(echo "$package" | jq -r '.optional // "missing"')
                
                if [[ "$name" == "missing" ]]; then
                    error "Paquete sin nombre en categoría $id"
                    ((errors++))
                fi
                
                if [[ "$repo" == "missing" ]]; then
                    error "Paquete $name sin repositorio en categoría $id"
                    ((errors++))
                fi
                
                if [[ "$optional" == "missing" ]]; then
                    warning "Paquete $name sin campo 'optional' en categoría $id"
                fi
                
                if [[ "$repo" != "pacman" && "$repo" != "aur" ]]; then
                    error "Repositorio inválido '$repo' para paquete $name"
                    ((errors++))
                fi
                
                if [[ "$optional" != "true" && "$optional" != "false" && "$optional" != "missing" ]]; then
                    error "Valor 'optional' inválido '$optional' para paquete $name"
                    ((errors++))
                fi
            fi
        done <<< "$packages"
        
    done <<< "$categories"
    
    if [[ $errors -eq 0 ]]; then
        success "✅ JSON válido - sin errores críticos"
        return 0
    else
        error "❌ Se encontraron $errors errores críticos"
        return 1
    fi
}

# ==============================================================================
# LISTADO Y CONSULTAS
# ==============================================================================

list_categories() {
    info "📦 Categorías disponibles:"
    echo
    
    jq -r '.categories[] | "\(.emoji) \(.id) - \(.description)"' "$PACKAGES_JSON" | \
    while IFS= read -r line; do
        echo "  $line"
    done
}

list_packages() {
    local category="$1"
    
    if [[ -n "$category" ]]; then
        info "📋 Paquetes en categoría: $category"
        echo
        
        local packages
        packages=$(jq --arg cat "$category" -r '.categories[] | select(.id == $cat) | .packages[]? | "\(.name) (\(.repo)) [\(.optional)]"' "$PACKAGES_JSON")
        
        if [[ -z "$packages" ]]; then
            warning "No se encontraron paquetes en la categoría '$category'"
            return 1
        fi
        
        echo "$packages" | while IFS= read -r line; do
            echo "  📦 $line"
        done
    else
        info "📋 Todos los paquetes:"
        echo
        
        jq -r '.categories[] as $cat | $cat.packages[]? | "\($cat.emoji) \(.name) (\(.repo)) [\(.optional)] - \($cat.id)"' "$PACKAGES_JSON" | \
        while IFS= read -r line; do
            echo "  $line"
        done
    fi
}

show_stats() {
    info "📊 Estadísticas del archivo packages.json:"
    echo
    
    local total_categories total_packages pacman_packages aur_packages optional_packages required_packages
    
    total_categories=$(jq '.categories | length' "$PACKAGES_JSON")
    total_packages=$(jq '[.categories[].packages[]?] | length' "$PACKAGES_JSON")
    pacman_packages=$(jq '[.categories[].packages[]? | select(.repo == "pacman")] | length' "$PACKAGES_JSON")
    aur_packages=$(jq '[.categories[].packages[]? | select(.repo == "aur")] | length' "$PACKAGES_JSON")
    optional_packages=$(jq '[.categories[].packages[]? | select(.optional == true)] | length' "$PACKAGES_JSON")
    required_packages=$(jq '[.categories[].packages[]? | select(.optional == false)] | length' "$PACKAGES_JSON")
    
    echo "  📁 Total de categorías: $total_categories"
    echo "  📦 Total de paquetes: $total_packages"
    echo "  🏛️  Paquetes oficiales (pacman): $pacman_packages"
    echo "  🔧 Paquetes de AUR: $aur_packages"
    echo "  ⚙️  Paquetes obligatorios: $required_packages"
    echo "  📋 Paquetes opcionales: $optional_packages"
    echo
    
    # Top 5 categorías con más paquetes
    echo "  🏆 Top 5 categorías con más paquetes:"
    jq -r '.categories[] | "\(.id): \(.packages | length) paquetes"' "$PACKAGES_JSON" | \
    sort -k2 -nr | head -5 | while IFS= read -r line; do
        echo "    • $line"
    done
}

# ==============================================================================
# GESTIÓN DE PAQUETES
# ==============================================================================

add_package_interactive() {
    info "➕ Agregar nuevo paquete"
    echo
    
    # Mostrar categorías disponibles
    echo "Categorías disponibles:"
    jq -r '.categories[] | "  \(.id) - \(.description)"' "$PACKAGES_JSON"
    echo
    
    # Solicitar información del paquete
    read -p "Nombre del paquete: " package_name
    read -p "Descripción: " package_desc
    read -p "Repositorio (pacman/aur): " package_repo
    read -p "¿Es opcional? (true/false): " package_optional
    read -p "URL de documentación: " package_url
    read -p "ID de categoría: " category_id
    
    # Validar entrada
    if [[ -z "$package_name" || -z "$category_id" ]]; then
        error "Nombre del paquete e ID de categoría son obligatorios"
        return 1
    fi
    
    if [[ "$package_repo" != "pacman" && "$package_repo" != "aur" ]]; then
        error "Repositorio debe ser 'pacman' o 'aur'"
        return 1
    fi
    
    if [[ "$package_optional" != "true" && "$package_optional" != "false" ]]; then
        error "El campo opcional debe ser 'true' o 'false'"
        return 1
    fi
    
    # Verificar que la categoría existe
    if ! jq -e --arg cat "$category_id" '.categories[] | select(.id == $cat)' "$PACKAGES_JSON" >/dev/null; then
        error "La categoría '$category_id' no existe"
        return 1
    fi
    
    # Verificar que el paquete no existe ya
    if jq -e --arg pkg "$package_name" '.categories[].packages[]? | select(.name == $pkg)' "$PACKAGES_JSON" >/dev/null; then
        error "El paquete '$package_name' ya existe"
        return 1
    fi
    
    # Crear backup antes de modificar
    backup_json
    
    # Agregar el paquete
    local temp_file
    temp_file=$(mktemp)
    
    jq --arg cat "$category_id" \
       --arg name "$package_name" \
       --arg desc "$package_desc" \
       --arg repo "$package_repo" \
       --argjson opt "$package_optional" \
       --arg url "$package_url" \
       '(.categories[] | select(.id == $cat) | .packages) += [{
         name: $name,
         description: $desc,
         optional: $opt,
         repo: $repo,
         url: $url
       }]' "$PACKAGES_JSON" > "$temp_file" && mv "$temp_file" "$PACKAGES_JSON"
    
    success "✅ Paquete '$package_name' agregado a la categoría '$category_id'"
}

remove_package() {
    local package_name="$1"
    
    if [[ -z "$package_name" ]]; then
        error "Debe especificar el nombre del paquete a eliminar"
        return 1
    fi
    
    # Verificar que el paquete existe
    if ! jq -e --arg pkg "$package_name" '.categories[].packages[]? | select(.name == $pkg)' "$PACKAGES_JSON" >/dev/null; then
        error "El paquete '$package_name' no existe"
        return 1
    fi
    
    # Crear backup antes de modificar
    backup_json
    
    # Eliminar el paquete
    local temp_file
    temp_file=$(mktemp)
    
    jq --arg pkg "$package_name" \
       '(.categories[].packages) |= map(select(.name != $pkg))' \
       "$PACKAGES_JSON" > "$temp_file" && mv "$temp_file" "$PACKAGES_JSON"
    
    success "✅ Paquete '$package_name' eliminado"
}

# ==============================================================================
# BACKUP Y RESTAURACIÓN
# ==============================================================================

backup_json() {
    local backup_dir="$SCRIPT_DIR/backups"
    local backup_file="$backup_dir/packages_$(date +%Y%m%d_%H%M%S).json"
    
    mkdir -p "$backup_dir"
    cp "$PACKAGES_JSON" "$backup_file"
    
    info "💾 Backup creado: $backup_file"
}

restore_json() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        error "Debe especificar el archivo de backup"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        error "Archivo de backup no encontrado: $backup_file"
        return 1
    fi
    
    if ! jq empty "$backup_file" 2>/dev/null; then
        error "El archivo de backup no es un JSON válido"
        return 1
    fi
    
    # Crear backup del archivo actual antes de restaurar
    backup_json
    
    cp "$backup_file" "$PACKAGES_JSON"
    success "✅ Archivo restaurado desde: $backup_file"
}

# ==============================================================================
# FUNCIÓN PRINCIPAL
# ==============================================================================

main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        validate)
            validate_json
            ;;
        list-categories)
            list_categories
            ;;
        list-packages)
            list_packages "${1:-}"
            ;;
        add-package)
            add_package_interactive
            ;;
        remove-package)
            remove_package "${1:-}"
            ;;
        stats)
            show_stats
            ;;
        backup)
            backup_json
            ;;
        restore)
            restore_json "${1:-}"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Comando desconocido: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
