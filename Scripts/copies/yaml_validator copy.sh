#!/bin/bash
# filepath: /home/deivi/dotfiles-dev/Scripts/yaml_validator.sh

# ==============================================================================
# YAML Package Validator
# Script para validar integridad de packages.yaml
# ==============================================================================

set -uo pipefail

# Configuración de rutas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_YAML="$SCRIPT_DIR/packages.yaml"

# Colores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Contadores globales
declare -g TOTAL_PACKAGES=0
declare -g AVAILABLE_PACMAN=0
declare -g AVAILABLE_AUR=0
declare -g NOT_FOUND=0
declare -g ALREADY_INSTALLED=0
declare -g NOT_INSTALLED=0
declare -g REQUIRED_PACKAGES=0
declare -g OPTIONAL_PACKAGES=0

# ==============================================================================
# FUNCIONES DE LOGGING - COPIADAS DEL FULL INSTALLER
# ==============================================================================

log() {
    local level="$1"
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*"
}

info() { log "INFO" "$@"; }
success() { log "SUCCESS" "\033[32m$*\033[0m"; }
warning() { log "WARNING" "\033[33m$*\033[0m"; }
error() { log "ERROR" "\033[31m$*\033[0m"; }

# ==============================================================================
# PREREQUISITOS
# ==============================================================================

check_prerequisites() {
    info "🔍 Verificando prerequisitos..."
    echo
    
    local missing_tools=()
    
    # Verificar herramientas necesarias
    if ! command -v yq &>/dev/null; then
        missing_tools+=("yq")
    fi
    
    if ! command -v pacman &>/dev/null; then
        missing_tools+=("pacman")
    fi
    
    if ! command -v yay &>/dev/null; then
        warning "yay no encontrado - no se podrán verificar paquetes AUR"
    fi
    
    # Verificar archivo YAML
    if [[ ! -f "$PACKAGES_YAML" ]]; then
        error "❌ Archivo packages.yaml no encontrado: $PACKAGES_YAML"
        exit 1
    fi
    
    # Instalar herramientas faltantes
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        warning "Herramientas faltantes: ${missing_tools[*]}"
        info "Instalando herramientas necesarias..."
        
        for tool in "${missing_tools[@]}"; do
            case "$tool" in
                "yq")
                    if ! sudo pacman -S --noconfirm --needed yq; then
                        error "❌ No se pudo instalar yq"
                        exit 1
                    fi
                    ;;
            esac
        done
    fi
    
    # Verificar integridad del YAML
    if ! yq -r '.categories[].id' "$PACKAGES_YAML" &>/dev/null; then
        error "❌ Archivo YAML inválido o corrupto"
        exit 1
    fi
    
    success "✅ Todos los prerequisitos están satisfechos"
    echo
}

# ==============================================================================
# VALIDACIÓN DE PAQUETES
# ==============================================================================

check_package_availability() {
    local pkg="$1"
    local repo_hint="$2"
    
    # Verificar si está instalado
    local is_installed=false
    if pacman -Qi "$pkg" &>/dev/null; then
        is_installed=true
        ((ALREADY_INSTALLED++))
    else
        ((NOT_INSTALLED++))
    fi
    
    # Verificar disponibilidad en repositorios
    local available_in=""
    local status_icon=""
    local install_status=""
    
    if $is_installed; then
        install_status="[INSTALADO]"
    else
        install_status="[NO INSTALADO]"
    fi
    
    # Verificar en pacman primero
    if pacman -Si "$pkg" &>/dev/null; then
        available_in="pacman"
        status_icon="✅"
        ((AVAILABLE_PACMAN++))
    elif command -v yay &>/dev/null && yay -Si "$pkg" &>/dev/null; then
        available_in="AUR"
        status_icon="🔷"
        ((AVAILABLE_AUR++))
    else
        available_in="NOT_FOUND"
        status_icon="❌"
        ((NOT_FOUND++))
    fi
    
    # Verificar si coincide con el repo sugerido
    local repo_match=""
    if [[ "$repo_hint" != "$available_in" ]] && [[ "$available_in" != "NOT_FOUND" ]]; then
        repo_match="⚠️ (sugerido: $repo_hint)"
    fi
    
    echo "  $status_icon $pkg $install_status - $available_in $repo_match"
    
    ((TOTAL_PACKAGES++))
}

# Funciones para barra de progreso y análisis light
count_total_packages() {
    yq '[.categories[].packages[].name] | length' "$PACKAGES_YAML"
}

update_counters_only() {
    local pkg="$1" repo_hint="$2" is_installed=false
    # Verificar instalación
    if pacman -Qi "$pkg" &>/dev/null; then
        is_installed=true
        ((ALREADY_INSTALLED++))
    else
        ((NOT_INSTALLED++))
    fi
    ((TOTAL_PACKAGES++))
    # Verificar disponibilidad
    if pacman -Si "$pkg" &>/dev/null; then
        ((AVAILABLE_PACMAN++))
    elif command -v yay &>/dev/null && yay -Si "$pkg" &>/dev/null; then
        ((AVAILABLE_AUR++))
    else
        ((NOT_FOUND++))
    fi
}

show_progress_bar() {
    # Prevenir variables sin definir y división por cero
    local current="${1:-0}" total="${2:-1}"
    local percent=0
    if (( total > 0 )); then
        percent=$((current*100/total))
    fi
    local width=50
    local filled=$((percent*width/100))
    local empty=$((width-filled))
    local barFilled=$(printf '%0.s#' $(seq 1 $filled))
    local barEmpty=$(printf '%0.s-' $(seq 1 $empty))
    printf "\r[%s%s] %d%%" "$barFilled" "$barEmpty" "$percent"
}

analyze_with_progress() {
    info "🔄 Analizando paquetes con progreso..."
    echo
    local total=$(count_total_packages) processed=0
    mapfile -t names < <(yq -r '.categories[].packages[].name' "$PACKAGES_YAML")
    mapfile -t repos < <(yq -r '.categories[].packages[].repo // "pacman"' "$PACKAGES_YAML")
    for i in "${!names[@]}"; do
        update_counters_only "${names[$i]}" "${repos[$i]}"
        ((processed++))
        show_progress_bar "$processed" "$total"
    done
    echo    # Nueva línea tras barra de progreso
    echo    # Separación adicional para visibilidad
}

# ==============================================================================
# ANÁLISIS POR CATEGORÍAS
# ==============================================================================

analyze_categories() {
    info "📊 Análisis de integridad por categorías"
    echo
    
    # Leer todas las categorías usando mapfile como en full installer
    local categories=()
    while IFS= read -r category_id; do
        if [[ -n "$category_id" ]] && [[ "$category_id" != "null" ]]; then
            categories+=("$category_id")
        fi
    done < <(yq -r '.categories[].id' "$PACKAGES_YAML")
    
    for cat in "${categories[@]}"; do
        analyze_category "$cat"
    done
}

# Mejorar la sintaxis de salida para mostrar paquetes por grupo
analyze_category() {
    local category_id="$1"
    info "📁 Analizando categoría: $category_id"

    # Obtener información de la categoría
    local desc pkg_count
    desc=$(yq -r ".categories[] | select(.id == \"${category_id}\") | .description // \"Sin descripción\"" "$PACKAGES_YAML")
    pkg_count=$(yq -r ".categories[] | select(.id == \"${category_id}\") | .packages | length" "$PACKAGES_YAML")

    info "   📋 Descripción: $desc"
    info "   📊 Número de paquetes: $pkg_count"

    # Pre-cargar nombres y descripciones desde el bloque de la categoría
    local -a pkg_names pkg_descs
    mapfile -t pkg_names < <(yq -r ".categories[] | select(.id == \"${category_id}\") | .packages[].name" "$PACKAGES_YAML")
    mapfile -t pkg_descs < <(yq -r ".categories[] | select(.id == \"${category_id}\") | .packages[].description // \"\"" "$PACKAGES_YAML")

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Resumen de la categoría: $category_id"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Cargar repositorios sugeridos
    local -a pkg_repos
    mapfile -t pkg_repos < <(yq -r ".categories[] | select(.id == \"${category_id}\") | .packages[] | .repo // \"pacman\"" "$PACKAGES_YAML")
    # Verificar cada paquete: imprime estado y actualiza contadores
    for i in "${!pkg_names[@]}"; do
        check_package_availability "${pkg_names[$i]}" "${pkg_repos[$i]}"
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ==============================================================================
# RESÚMENES Y ESTADÍSTICAS
# ==============================================================================

show_summary() {
    info "📈 Resumen de validación"
    echo

    # Estadísticas generales
    info "🔢 Estadísticas generales:"
    echo "  📦 Total de paquetes: $TOTAL_PACKAGES"
    echo "  🟢 Disponibles en pacman: $AVAILABLE_PACMAN"
    echo "  🔷 Disponibles en AUR: $AVAILABLE_AUR"
    echo "  ❌ No encontrados: $NOT_FOUND"
    echo

    # Estado de instalación
    info "💾 Estado de instalación:"
    echo "  ✅ Ya instalados: $ALREADY_INSTALLED"
    echo "  ⏳ Por instalar: $NOT_INSTALLED"
    echo

    # Porcentajes
    if [[ $TOTAL_PACKAGES -gt 0 ]]; then
        local available_percent installed_percent
        available_percent=$(( (AVAILABLE_PACMAN + AVAILABLE_AUR) * 100 / TOTAL_PACKAGES ))
        installed_percent=$(( ALREADY_INSTALLED * 100 / TOTAL_PACKAGES ))

        info "📊 Porcentajes:"
        echo "  🎯 Disponibilidad: ${available_percent}%"
        echo "  💿 Instalados: ${installed_percent}%"
        echo
    fi
}

show_problematic_packages() {
    if [[ $NOT_FOUND -eq 0 ]]; then
        success "🎉 ¡No se encontraron paquetes problemáticos!"
        echo
        return 0
    fi
    
    error "⚠️  Se encontraron $NOT_FOUND paquetes problemáticos:"
    echo
    
    # Usar la misma lógica del full installer - cargar categorías primero
    local categories=()
    while IFS= read -r category_id; do
        if [[ -n "$category_id" ]] && [[ "$category_id" != "null" ]]; then
            categories+=("$category_id")
        fi
    done < <(yq -r '.categories[].id' "$PACKAGES_YAML")
    
    # Iterar por cada categoría usando bucle for como en full installer
    for cat in "${categories[@]}"; do
        local has_problems=false
        
        # Cargar arrays de paquetes para esta categoría
        local -a pkg_names pkg_repos
        mapfile -t pkg_names < <(yq -r ".categories[] | select(.id == \"${cat}\") | .packages[].name" "$PACKAGES_YAML")
        mapfile -t pkg_repos < <(yq -r ".categories[] | select(.id == \"${cat}\") | .packages[] | .repo // \"pacman\"" "$PACKAGES_YAML")
        
        # Verificar cada paquete de la categoría
        for i in "${!pkg_names[@]}"; do
            local pkg_name="${pkg_names[$i]}"
            local pkg_repo="${pkg_repos[$i]:-pacman}"
            
            # Verificar si el paquete no existe en ningún repo
            if ! pacman -Si "$pkg_name" &>/dev/null && \
               ! (command -v yay &>/dev/null && yay -Si "$pkg_name" &>/dev/null); then
                if ! $has_problems; then
                    echo "  📁 $cat:"
                    has_problems=true
                fi
                echo "    ❌ $pkg_name (sugerido: $pkg_repo)"
            fi
        done
        
        if $has_problems; then
            echo
        fi
    done
}

show_pending_installations() {
    info "📥 Paquetes pendientes de instalación"
    echo
    
    local has_pending=false
    
    # Usar la misma lógica del full installer - cargar categorías primero
    local categories=()
    while IFS= read -r category_id; do
        if [[ -n "$category_id" ]] && [[ "$category_id" != "null" ]]; then
            categories+=("$category_id")
        fi
    done < <(yq -r '.categories[].id' "$PACKAGES_YAML")
    
    # Iterar por cada categoría usando bucle for como en full installer
    for cat in "${categories[@]}"; do
        local category_has_pending=false
        local desc
        desc=$(yq -r ".categories[] | select(.id == \"${cat}\") | .description // \"Sin descripción\"" "$PACKAGES_YAML")
        
        # Cargar arrays de paquetes para esta categoría
        local -a pkg_names pkg_optionals
        mapfile -t pkg_names < <(yq -r ".categories[] | select(.id == \"${cat}\") | .packages[].name" "$PACKAGES_YAML")
        mapfile -t pkg_optionals < <(yq -r ".categories[] | select(.id == \"${cat}\") | .packages[] | .optional // false" "$PACKAGES_YAML")
        
        # Verificar cada paquete de la categoría
        for i in "${!pkg_names[@]}"; do
            local pkg_name="${pkg_names[$i]}"
            local pkg_optional="${pkg_optionals[$i]:-false}"
            
            # Verificar si NO está instalado
            if ! pacman -Qi "$pkg_name" &>/dev/null; then
                if ! $category_has_pending; then
                    echo "  📁 $cat ($desc):"
                    category_has_pending=true
                    has_pending=true
                fi
                
                local priority_marker=""
                if [[ "$pkg_optional" == "true" ]]; then
                    priority_marker="[OPCIONAL]"
                else
                    priority_marker="[REQUERIDO]"
                fi
                
                echo "    ⏳ $pkg_name $priority_marker"
            fi
        done
        
        if $category_has_pending; then
            echo
        fi
    done
    
    if ! $has_pending; then
        success "🎉 ¡Todos los paquetes ya están instalados!"
        echo
    fi
}

# ==============================================================================
# MENÚ PRINCIPAL
# ==============================================================================

show_menu() {
    info "🔍 YAML Package Validator"
    echo
    echo "Opciones disponibles:"
    echo "1) 📊 Análisis completo de integridad"
    echo "2) ⚠️  Mostrar solo paquetes problemáticos"
    echo "3) 📥 Mostrar paquetes pendientes de instalación"
    echo "4) 📈 Mostrar solo estadísticas"
    echo "5) 🚪 Salir"
    echo
}

# Función para reiniciar contadores
reset_counters() {
    TOTAL_PACKAGES=0 AVAILABLE_PACMAN=0 AVAILABLE_AUR=0 NOT_FOUND=0
    ALREADY_INSTALLED=0 NOT_INSTALLED=0 REQUIRED_PACKAGES=0 OPTIONAL_PACKAGES=0
}

# Función para cálculo rápido de estadísticas usando mapfile - IGUAL que full installer
calculate_stats() {
    info "🔄 Calculando estadísticas..."
    
    reset_counters
    
    # Cargar categorías primero, igual que en full installer
    local categories=()
    while IFS= read -r category_id; do
        if [[ -n "$category_id" ]] && [[ "$category_id" != "null" ]]; then
            categories+=("$category_id")
        fi
    done < <(yq -r '.categories[].id' "$PACKAGES_YAML")
    
    # Iterar por cada categoría usando bucle for, igual que en full installer
    for cat in "${categories[@]}"; do
        # Cargar arrays de paquetes para esta categoría
        local -a pkg_names pkg_optionals
        mapfile -t pkg_names < <(yq -r ".categories[] | select(.id == \"${cat}\") | .packages[].name" "$PACKAGES_YAML")
        mapfile -t pkg_optionals < <(yq -r ".categories[] | select(.id == \"${cat}\") | .packages[] | .optional // false" "$PACKAGES_YAML")
        
        # Procesar cada paquete de la categoría
        for i in "${!pkg_names[@]}"; do
            local pkg_name="${pkg_names[$i]}"
            local pkg_optional="${pkg_optionals[$i]:-false}"
            
            ((TOTAL_PACKAGES++))
            
            # Contar por prioridad
            if [[ "$pkg_optional" == "false" ]]; then
                ((REQUIRED_PACKAGES++))
            else
                ((OPTIONAL_PACKAGES++))
            fi
            
            # Verificar instalación
            if pacman -Qi "$pkg_name" &>/dev/null; then
                ((ALREADY_INSTALLED++))
            else
                ((NOT_INSTALLED++))
            fi
            
            # Verificar disponibilidad
            if pacman -Si "$pkg_name" &>/dev/null; then
                ((AVAILABLE_PACMAN++))
            elif command -v yay &>/dev/null && yay -Si "$pkg_name" &>/dev/null; then
                ((AVAILABLE_AUR++))
            else
                ((NOT_FOUND++))
            fi
        done
    done
}

main() {
    check_prerequisites
    
    while true; do
        show_menu
        read -p "Selecciona una opción [1-5]: " choice
        echo
        
        case $choice in
            1)
                reset_counters
                analyze_categories
                show_summary
                show_problematic_packages
                ;;
            2)
                reset_counters
                analyze_with_progress  # Análisis ligero con progreso
                show_problematic_packages
                ;;
            3)
                show_pending_installations
                ;;
            4)
                reset_counters
                analyze_with_progress  # Análisis ligero con progreso
                show_summary
                ;;
            5)
                info "👋 ¡Hasta luego!"
                exit 0
                ;;
            *)
                warning "Opción inválida. Por favor selecciona 1-5."
                ;;
        esac
        
        echo
        read -p "Presiona Enter para continuar..."
        echo
    done
}

# Ejecutar script
main "$@"