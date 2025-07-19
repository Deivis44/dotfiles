#!/bin/bash

# ==============================================================================
# DOTFILES PACKAGE INSTALLER v2.0 - JSON NATIVE
# Sistema modular basado 100% en packages.json sin dependencias legacy
# ==============================================================================

set -euo pipefail  # Modo estricto

# Configuraciones globales
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"
readonly LOG_DIR="$HOME/.local/share/dotfiles/logs"
readonly CONFIG_DIR="$HOME/.config/dotfiles"
readonly STATE_FILE="$CONFIG_DIR/installation_state.json"

# Crear directorios necesarios
mkdir -p "$LOG_DIR" "$CONFIG_DIR"

# Logging con timestamp
readonly LOG_FILE="$LOG_DIR/installation_$(date +%Y%m%d_%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# ==============================================================================
# FUNCIONES DE UTILIDAD Y LOGGING
# ==============================================================================

log() {
    local level="$1"
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

info() { log "INFO" "$@"; }
success() { log "SUCCESS" "\033[32m$*\033[0m"; }
warning() { log "WARNING" "\033[33m$*\033[0m"; }
error() { log "ERROR" "\033[31m$*\033[0m"; }

show_banner() {
    cat << 'EOF'
     _____          ___         ___       
    /  /::\        /  /\       /__/\      
   /  /:/\:\      /  /::\     |  |::\     
  /  /:/  \:\    /  /:/\:\    |  |:|:\    
 /__/:/ \__\:|  /  /:/~/:/  __|__|:|\:\   
 \  \:\ /  /:/ /__/:/ /:/  /__/::::| \:\  
  \  \:\  /:/  \  \:\/:/   \  \:\~~\__\/  
   \  \:\/:/    \  \::/     \  \:\        
    \  \::/      \  \:\      \  \:\       
     \__\/        \  \:\      \  \:\      
                   \__\/       \__\/      

╔══════════════════════════════════════════════════════════════════════╗
║                 🚀 DOTFILES PACKAGE INSTALLER v2.0                  ║
║                     JSON-Native • Arch Linux                         ║
║                    $(date +'%Y-%m-%d %H:%M:%S')                       ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
}

show_progress() {
    local current=$1
    local total=$2
    local desc="$3"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    
    printf "\r[%s%s] %d/%d (%d%%) - %s" \
        "$(printf '#%.0s' $(seq 1 $filled))" \
        "$(printf ' %.0s' $(seq 1 $((width - filled))))" \
        "$current" "$total" "$percentage" "$desc"
}

# ==============================================================================
# VALIDACIÓN Y DEPENDENCIAS
# ==============================================================================

check_dependencies() {
    info "Verificando dependencias del sistema..."
    
    local deps=("jq" "curl" "git")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        warning "Dependencias faltantes: ${missing[*]}"
        info "Instalando dependencias..."
        sudo pacman -S --needed --noconfirm "${missing[@]}"
    fi
    
    # Verificar JSON
    if [[ ! -f "$PACKAGES_JSON" ]]; then
        error "Archivo packages.json no encontrado en: $PACKAGES_JSON"
        exit 1
    fi
    
    if ! jq empty "$PACKAGES_JSON" 2>/dev/null; then
        error "El archivo packages.json no es válido"
        exit 1
    fi
    
    success "Todas las dependencias están disponibles"
}

install_aur_helper() {
    if command -v yay >/dev/null 2>&1; then
        info "yay ya está instalado"
        return 0
    fi
    
    info "Instalando yay (AUR helper)..."
    
    # Instalar dependencias para compilar yay
    sudo pacman -S --needed --noconfirm base-devel git
    
    # Crear directorio temporal
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Clonar e instalar yay
    git clone https://aur.archlinux.org/yay.git "$temp_dir/yay"
    cd "$temp_dir/yay"
    makepkg -si --noconfirm
    
    # Limpiar
    cd "$SCRIPT_DIR"
    rm -rf "$temp_dir"
    
    if command -v yay >/dev/null 2>&1; then
        success "yay instalado correctamente"
    else
        error "Error al instalar yay"
        exit 1
    fi
}

# ==============================================================================
# GESTIÓN DE ESTADO
# ==============================================================================

init_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        cat > "$STATE_FILE" << 'EOF'
{
  "installation_started": null,
  "installation_completed": null,
  "installed_categories": [],
  "installed_packages": {},
  "failed_packages": {},
  "user_choices": {}
}
EOF
    fi
}

save_package_state() {
    local package="$1"
    local status="$2"
    local category="$3"
    
    local temp_file
    temp_file=$(mktemp)
    
    jq --arg pkg "$package" --arg status "$status" --arg cat "$category" \
       '.installed_packages[$pkg] = {status: $status, category: $cat, timestamp: now | todate}' \
       "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
}

is_package_installed() {
    local package="$1"
    pacman -Qi "$package" >/dev/null 2>&1 || yay -Qi "$package" >/dev/null 2>&1
}

# ==============================================================================
# INTERACCIÓN CON USUARIO
# ==============================================================================

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

select_installation_mode() {
    echo
    echo "🔧 Modos de instalación disponibles:"
    echo "1) Instalación completa (todos los paquetes)"
    echo "2) Instalación por categorías"
    echo "3) Instalación selectiva (paquete por paquete)"
    echo "4) Solo paquetes obligatorios"
    echo
    
    while true; do
        read -p "Selecciona un modo [1-4]: " mode
        case "$mode" in
            1) echo "full"; return ;;
            2) echo "categories"; return ;;
            3) echo "selective"; return ;;
            4) echo "required_only"; return ;;
            *) echo "Por favor, selecciona una opción válida (1-4)" ;;
        esac
    done
}

select_categories() {
    echo
    info "📦 Categorías disponibles en tu JSON:"
    echo
    
    # Leer categorías directamente del JSON actual
    local categories=()
    local i=1
    
    while IFS= read -r category_line; do
        local id emoji desc
        id=$(echo "$category_line" | jq -r '.id')
        emoji=$(echo "$category_line" | jq -r '.emoji')
        desc=$(echo "$category_line" | jq -r '.description')
        
        printf "%2d) %s %s\n" "$i" "$emoji" "$id"
        printf "     └─ %s\n" "$desc"
        echo
        
        categories+=("$id")
        ((i++))
    done < <(jq -c '.categories[]' "$PACKAGES_JSON")
    
    echo "────────────────────────────────────────────────────────────────────────"
    echo "💡 Opciones de selección:"
    echo "   • Números separados por comas: 1,3,5,7"
    echo "   • Rangos: 1-5 (categorías 1 a 5)"
    echo "   • Combinado: 1,3-5,8 (categorías 1, 3 a 5, y 8)"
    echo "   • 'all' para todas las categorías"
    echo "────────────────────────────────────────────────────────────────────────"
    
    while true; do
        read -p "🎯 Selecciona categorías: " selection
        
        if [[ "$selection" == "all" ]]; then
            printf '%s\n' "${categories[@]}"
            return 0
        fi
        
        local selected=()
        local valid=true
        
        # Procesar selección (soporta rangos y listas)
        IFS=',' read -ra parts <<< "$selection"
        for part in "${parts[@]}"; do
            part=$(echo "$part" | tr -d ' ')
            
            if [[ "$part" =~ ^[0-9]+$ ]]; then
                # Número simple
                if (( part >= 1 && part <= ${#categories[@]} )); then
                    selected+=("${categories[$((part-1))]}")
                else
                    error "Número fuera de rango: $part"
                    valid=false
                    break
                fi
            elif [[ "$part" =~ ^[0-9]+-[0-9]+$ ]]; then
                # Rango (ej: 1-5)
                local start end
                start=$(echo "$part" | cut -d'-' -f1)
                end=$(echo "$part" | cut -d'-' -f2)
                
                if (( start >= 1 && end <= ${#categories[@]} && start <= end )); then
                    for ((j=start; j<=end; j++)); do
                        selected+=("${categories[$((j-1))]}")
                    done
                else
                    error "Rango inválido: $part"
                    valid=false
                    break
                fi
            else
                error "Formato inválido: $part"
                valid=false
                break
            fi
        done
        
        if [[ "$valid" == "true" ]] && [[ ${#selected[@]} -gt 0 ]]; then
            # Eliminar duplicados manteniendo orden
            local unique_selected=()
            for item in "${selected[@]}"; do
                if [[ ! " ${unique_selected[*]} " =~ " ${item} " ]]; then
                    unique_selected+=("$item")
                fi
            done
            
            printf '%s\n' "${unique_selected[@]}"
            return 0
        else
            warning "Selección inválida. Intenta de nuevo."
            echo
        fi
    done
}

# ==============================================================================
# INSTALACIÓN DE PAQUETES
# ==============================================================================

install_package() {
    local package="$1"
    local repo="$2"
    local optional="$3"
    local category="$4"
    local install_mode="$5"
    
    # Verificar si ya está instalado (usando la lógica original)
    if pacman -Qi "$package" >/dev/null 2>&1 || yay -Qi "$package" >/dev/null 2>&1; then
        info "📦 $package ya está instalado"
        save_package_state "$package" "already_installed" "$category"
        return 0
    fi
    
    # Verificar modo de instalación para paquetes opcionales
    if [[ "$optional" == "true" ]] && [[ "$install_mode" == "required_only" ]]; then
        info "⏭️  Omitiendo $package (paquete opcional)"
        save_package_state "$package" "skipped_optional" "$category"
        return 0
    fi
    
    # Preguntar al usuario en modo selectivo (lógica original)
    if [[ "$install_mode" == "selective" ]]; then
        while true; do
            read -p "¿Instalar $package? [s/n]: " yn
            case $yn in
                [Ss]* ) break;;
                [Nn]* ) 
                    info "⏭️  Usuario omitió $package"
                    save_package_state "$package" "user_skipped" "$category"
                    return 0
                    ;;
                * ) echo "Por favor, responde con s/n.";;
            esac
        done
    fi
    
    info "🔄 Instalando $package desde $repo..."
    
    # Lógica de instalación original: primero pacman, luego yay
    local success=false
    if [[ "$repo" == "pacman" ]]; then
        if sudo pacman -S --noconfirm "$package" 2>/dev/null; then
            success=true
        else
            info "No se pudo instalar $package con pacman. Intentando con yay..."
            if command -v yay >/dev/null 2>&1 && yay -S --noconfirm "$package"; then
                success=true
            fi
        fi
    elif [[ "$repo" == "aur" ]]; then
        if command -v yay >/dev/null 2>&1 && yay -S --noconfirm "$package"; then
            success=true
        else
            error "yay no está disponible para instalar paquetes AUR"
        fi
    fi
    
    if [[ "$success" == "true" ]]; then
        success "✅ $package instalado correctamente"
        save_package_state "$package" "installed" "$category"
        return 0
    else
        error "❌ Error al instalar $package"
        save_package_state "$package" "failed" "$category"
        return 1
    fi
}

install_category() {
    local category_id="$1"
    local install_mode="$2"
    
    # Obtener información de la categoría desde JSON
    local category_info
    category_info=$(jq --arg cat "$category_id" '.categories[] | select(.id == $cat)' "$PACKAGES_JSON")
    
    if [[ -z "$category_info" ]] || [[ "$category_info" == "null" ]]; then
        error "Categoría '$category_id' no encontrada en packages.json"
        return 1
    fi
    
    local emoji desc packages_count
    emoji=$(echo "$category_info" | jq -r '.emoji // "📦"')
    desc=$(echo "$category_info" | jq -r '.description // "Sin descripción"')
    packages_count=$(echo "$category_info" | jq '.packages | length')
    
    echo
    info "🎯 Instalando: $emoji $category_id"
    echo "   📋 $desc"
    echo "   📊 $packages_count paquetes en esta categoría"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Instalar paquetes
    local current=0
    local installed=0
    local failed=0
    local skipped=0
    
    while IFS= read -r package_info; do
        if [[ -n "$package_info" ]] && [[ "$package_info" != "null" ]]; then
            ((current++))
            
            local name repo optional desc_pkg url
            name=$(echo "$package_info" | jq -r '.name // ""')
            repo=$(echo "$package_info" | jq -r '.repo // "pacman"')
            optional=$(echo "$package_info" | jq -r '.optional // false')
            desc_pkg=$(echo "$package_info" | jq -r '.description // ""')
            url=$(echo "$package_info" | jq -r '.url // ""')
            
            if [[ -z "$name" ]]; then
                warning "Paquete sin nombre encontrado, omitiendo..."
                continue
            fi
            
            # Mostrar progreso
            printf "\r🔄 [%d/%d] Procesando: %-30s" "$current" "$packages_count" "$name"
            
            # Mostrar información del paquete si está disponible
            if [[ -n "$desc_pkg" ]]; then
                echo
                info "   📝 $desc_pkg"
            fi
            
            if install_package "$name" "$repo" "$optional" "$category_id" "$install_mode"; then
                if pacman -Qi "$name" >/dev/null 2>&1 || yay -Qi "$name" >/dev/null 2>&1; then
                    ((installed++))
                else
                    ((skipped++))
                fi
            else
                ((failed++))
            fi
        fi
    done < <(echo "$category_info" | jq -c '.packages[]?')
    
    echo  # Nueva línea después de la barra de progreso
    echo
    
    # Mostrar resumen con colores
    if [[ $failed -eq 0 ]]; then
        success "✅ Categoría $category_id completada exitosamente"
    else
        warning "⚠️  Categoría $category_id completada con algunos errores"
    fi
    
    echo "   📊 Resumen:"
    echo "      ✅ Instalados: $installed"
    echo "      ⏭️  Omitidos: $skipped" 
    echo "      ❌ Fallidos: $failed"
    echo
    
    return $failed
}

# ==============================================================================
# FUNCIONES PRINCIPALES
# ==============================================================================

run_installation() {
    local install_mode="$1"
    shift
    local categories=("$@")
    
    info "🚀 Iniciando instalación en modo: $install_mode"
    
    # Actualizar sistema
    info "🔄 Actualizando sistema..."
    sudo pacman -Syu --noconfirm
    
    # Registrar inicio
    local temp_file
    temp_file=$(mktemp)
    jq '.installation_started = (now | todate)' "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
    
    # Instalar categorías
    for category in "${categories[@]}"; do
        install_category "$category" "$install_mode"
    done
    
    # Registrar finalización
    temp_file=$(mktemp)
    jq '.installation_completed = (now | todate)' "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
    
    show_installation_summary
}

show_installation_summary() {
    echo
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                        📋 RESUMEN DE INSTALACIÓN                     ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    
    local installed failed skipped
    installed=$(jq -r '.installed_packages | to_entries[] | select(.value.status == "installed") | .key' "$STATE_FILE" | wc -l)
    failed=$(jq -r '.installed_packages | to_entries[] | select(.value.status == "failed") | .key' "$STATE_FILE" | wc -l)
    skipped=$(jq -r '.installed_packages | to_entries[] | select(.value.status | test("skipped|user_skipped")) | .key' "$STATE_FILE" | wc -l)
    
    echo "✅ Paquetes instalados exitosamente: $installed"
    echo "❌ Paquetes que fallaron: $failed"
    echo "⏭️  Paquetes omitidos: $skipped"
    echo
    echo "📄 Log completo: $LOG_FILE"
    echo "💾 Estado guardado en: $STATE_FILE"
    
    if [[ $failed -gt 0 ]]; then
        echo
        warning "Paquetes que fallaron:"
        jq -r '.installed_packages | to_entries[] | select(.value.status == "failed") | "  - " + .key' "$STATE_FILE"
    fi
}

# ==============================================================================
# FUNCIÓN PRINCIPAL
# ==============================================================================

main() {
    show_banner
    
    # Verificaciones iniciales
    check_dependencies
    install_aur_helper
    init_state
    
    # Seleccionar modo de instalación
    local install_mode
    install_mode=$(select_installation_mode)
    
    # Seleccionar categorías según el modo
    local categories=()
    case "$install_mode" in
        "full"|"selective"|"required_only")
            # Leer todas las categorías del JSON actual
            while IFS= read -r category_id; do
                categories+=("$category_id")
            done < <(jq -r '.categories[].id' "$PACKAGES_JSON")
            ;;
        "categories")
            while IFS= read -r category_id; do
                if [[ -n "$category_id" ]]; then
                    categories+=("$category_id")
                fi
            done < <(select_categories)
            ;;
    esac
    
    if [[ ${#categories[@]} -eq 0 ]]; then
        warning "No se seleccionaron categorías para instalar"
        exit 0
    fi
    
    # Confirmar instalación
    echo
    info "Se instalarán las siguientes categorías: ${categories[*]}"
    if ! ask_yes_no "¿Continuar con la instalación?"; then
        info "Instalación cancelada por el usuario"
        exit 0
    fi
    
    # Ejecutar instalación
    run_installation "$install_mode" "${categories[@]}"
    
    success "🎉 ¡Instalación completada!"
}

# Manejar señales para limpieza
trap 'error "Instalación interrumpida"; exit 130' INT TERM

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
