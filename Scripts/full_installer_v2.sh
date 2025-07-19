#!/bin/bash

# ==============================================================================
# DOTFILES FULL INSTALLER v2.0 - JSON NATIVE
# Sistema completo unificado - Base de datos JSON única
# ==============================================================================

set -euo pipefail

# Configuraciones globales
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"
readonly ADDITIONAL_DIR="$SCRIPT_DIR/Additional"
readonly LOG_DIR="$HOME/.local/share/dotfiles/logs"
readonly CONFIG_DIR="$HOME/.config/dotfiles"

# Crear directorios necesarios
mkdir -p "$LOG_DIR" "$CONFIG_DIR"

# Logging con timestamp
readonly LOG_FILE="$LOG_DIR/full_installation_$(date +%Y%m%d_%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# Contadores globales para resumen
TOTAL_INSTALLED=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0

# ==============================================================================
# FUNCIONES DE UTILIDAD
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
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║                 🚀 DOTFILES FULL INSTALLER v2.0                     ║
║                     JSON-Native • Arch Linux                         ║
║                                                                      ║
║   ┌────────────────┬─────────────────────────────────────────────┐   ║
║   │ 📦 Packages    │ JSON-based package management               │   ║
║   │ 🔧 Tweaks      │ System optimizations & configurations      │   ║
║   │ 🔗 Symlinks    │ Configuration file linking                 │   ║
║   │ 📄 Logs        │ Complete installation tracking             │   ║
║   └────────────────┴─────────────────────────────────────────────┘   ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo "🕐 Sesión iniciada: $(date +'%Y-%m-%d %H:%M:%S')"
    echo "�� Directorio: $DOTFILES_DIR"
    echo "📄 Log: $LOG_FILE"
    echo
}

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

# ==============================================================================
# VALIDACIÓN Y DEPENDENCIAS
# ==============================================================================

check_dependencies() {
    info "🔍 Verificando dependencias del sistema..."
    
    local deps=("jq" "curl" "git" "stow")
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
    
    success "✅ Todas las dependencias están disponibles"
}

install_aur_helper() {
    if command -v yay >/dev/null 2>&1; then
        info "✅ yay ya está instalado"
        return 0
    fi
    
    info "📦 Instalando yay (AUR helper)..."
    
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
        success "✅ yay instalado correctamente"
    else
        error "❌ Error al instalar yay"
        exit 1
    fi
}

# ==============================================================================
# INSTALACIÓN DE PAQUETES JSON-NATIVE
# ==============================================================================

install_package() {
    local package="$1"
    local repo="$2"
    local optional="$3"
    local category="$4"
    local install_mode="$5"
    
    # Verificar si ya está instalado
    if pacman -Qi "$package" >/dev/null 2>&1 || yay -Qi "$package" >/dev/null 2>&1; then
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
    
    info "🔄 Instalando $package desde $repo..."
    
    # Lógica de instalación: primero pacman, luego yay
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
        ((TOTAL_INSTALLED++))
        return 0
    else
        error "❌ Error al instalar $package"
        ((TOTAL_FAILED++))
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
    
    while IFS= read -r package_info; do
        if [[ -n "$package_info" ]] && [[ "$package_info" != "null" ]]; then
            ((current++))
            
            local name repo optional desc_pkg
            name=$(echo "$package_info" | jq -r '.name // ""')
            repo=$(echo "$package_info" | jq -r '.repo // "pacman"')
            optional=$(echo "$package_info" | jq -r '.optional // false')
            desc_pkg=$(echo "$package_info" | jq -r '.description // ""')
            
            if [[ -z "$name" ]]; then
                warning "Paquete sin nombre encontrado, omitiendo..."
                continue
            fi
            
            # Mostrar progreso
            printf "🔄 [%d/%d] %-30s" "$current" "$packages_count" "$name"
            
            # Mostrar descripción si está disponible
            if [[ -n "$desc_pkg" ]]; then
                echo " - $desc_pkg"
            else
                echo
            fi
            
            install_package "$name" "$repo" "$optional" "$category_id" "$install_mode"
        fi
    done < <(echo "$category_info" | jq -c '.packages[]?')
    
    echo
}

select_installation_mode() {
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
    info "📦 Categorías disponibles:"
    echo
    
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
    echo "💡 Opciones: números separados por comas (1,3,5), rangos (1-5), o 'all'"
    echo "────────────────────────────────────────────────────────────────────────"
    
    while true; do
        read -p "🎯 Selecciona categorías: " selection
        
        if [[ "$selection" == "all" ]]; then
            printf '%s\n' "${categories[@]}"
            return 0
        fi
        
        local selected=()
        local valid=true
        
        IFS=',' read -ra parts <<< "$selection"
        for part in "${parts[@]}"; do
            part=$(echo "$part" | tr -d ' ')
            
            if [[ "$part" =~ ^[0-9]+$ ]]; then
                if (( part >= 1 && part <= ${#categories[@]} )); then
                    selected+=("${categories[$((part-1))]}")
                else
                    error "Número fuera de rango: $part"
                    valid=false
                    break
                fi
            elif [[ "$part" =~ ^[0-9]+-[0-9]+$ ]]; then
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
            # Eliminar duplicados
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

install_packages() {
    local install_mode="$1"
    shift
    local categories=("$@")
    
    info "🚀 Iniciando instalación de paquetes en modo: $install_mode"
    
    # Actualizar sistema
    info "🔄 Actualizando sistema..."
    sudo pacman -Syu --noconfirm
    
    # Instalar categorías
    for category in "${categories[@]}"; do
        install_category "$category" "$install_mode"
    done
}

# ==============================================================================
# SCRIPTS ADICIONALES
# ==============================================================================

run_additional_scripts() {
    if [[ ! -d "$ADDITIONAL_DIR" ]]; then
        warning "Directorio Additional/ no encontrado, omitiendo..."
        return 0
    fi
    
    echo
    info "🔧 Ejecutando scripts de configuración adicional..."
    echo
    
    # Lista de scripts adicionales disponibles
    local additional_scripts=(
        "Pacman.sh:🎨 Configuración avanzada de pacman"
        "MineGRUB.sh:⛏️  Tema Minecraft para GRUB"
        "fastfetch.sh:🚀 Configuración de fastfetch"
        "setup-bluetooth.sh:📶 Configuración de Bluetooth"
    )
    
    for script_info in "${additional_scripts[@]}"; do
        local script_name="${script_info%%:*}"
        local script_desc="${script_info#*:}"
        local script_path="$ADDITIONAL_DIR/$script_name"
        
        if [[ -f "$script_path" ]]; then
            echo "$script_desc"
            if ask_yes_no "¿Ejecutar $script_name?"; then
                info "Ejecutando $script_name..."
                if bash "$script_path"; then
                    success "✅ $script_name completado"
                else
                    error "❌ Error en $script_name"
                fi
            else
                info "⏭️  Omitiendo $script_name"
            fi
            echo
        fi
    done
}

run_extra_packages() {
    local extra_script="$SCRIPT_DIR/install_extra_packs.sh"
    
    if [[ -f "$extra_script" ]]; then
        echo
        info "📦 Script de paquetes adicionales disponible"
        if ask_yes_no "¿Ejecutar instalación de paquetes extra?"; then
            info "Ejecutando install_extra_packs.sh..."
            if bash "$extra_script"; then
                success "✅ Paquetes extra instalados"
            else
                error "❌ Error en paquetes extra"
            fi
        else
            info "⏭️  Omitiendo paquetes extra"
        fi
    fi
}

setup_symlinks() {
    local stow_script="$SCRIPT_DIR/stow-links.sh"
    
    if [[ -f "$stow_script" ]]; then
        echo
        info "🔗 Configuración de enlaces simbólicos disponible"
        if ask_yes_no "¿Configurar enlaces simbólicos de dotfiles?"; then
            info "Ejecutando stow-links.sh..."
            if bash "$stow_script"; then
                success "✅ Enlaces simbólicos configurados"
            else
                error "❌ Error en enlaces simbólicos"
            fi
        else
            info "⏭️  Omitiendo enlaces simbólicos"
        fi
    fi
}

# ==============================================================================
# RESUMEN FINAL
# ==============================================================================

show_final_summary() {
    echo
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    🎉 INSTALACIÓN COMPLETADA                        ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo
    echo "📊 Resumen de paquetes:"
    echo "   ✅ Instalados exitosamente: $TOTAL_INSTALLED"
    echo "   ❌ Fallidos: $TOTAL_FAILED"
    echo "   ⏭️  Omitidos: $TOTAL_SKIPPED"
    echo
    echo "📄 Log completo: $LOG_FILE"
    echo "🕐 Sesión finalizada: $(date +'%Y-%m-%d %H:%M:%S')"
    echo
    
    if [[ $TOTAL_FAILED -gt 0 ]]; then
        warning "⚠️  Algunos paquetes fallaron. Revisa el log para más detalles."
    else
        success "🚀 ¡Todos los paquetes se instalaron correctamente!"
    fi
    
    echo
    info "🔄 Recomendaciones post-instalación:"
    echo "   • Reinicia tu sesión para aplicar cambios de shell"
    echo "   • Revisa la configuración de Hyprland en ~/.config/hypr/"
    echo "   • Ejecuta 'fastfetch' para ver el resultado"
    echo
}

# ==============================================================================
# FUNCIÓN PRINCIPAL
# ==============================================================================

main() {
    show_banner
    
    # Verificaciones iniciales
    check_dependencies
    install_aur_helper
    
    # === FASE 1: INSTALACIÓN DE PAQUETES ===
    echo
    info "═══════════════════════════════════════════════════════════════"
    info "                    📦 FASE 1: PAQUETES                        "
    info "═══════════════════════════════════════════════════════════════"
    
    # Seleccionar modo de instalación
    local install_mode
    install_mode=$(select_installation_mode)
    
    # Seleccionar categorías según el modo
    local categories=()
    case "$install_mode" in
        "full"|"selective"|"required_only")
            info "🔍 Leyendo categorías del JSON..."
            while IFS= read -r category_id; do
                if [[ -n "$category_id" ]] && [[ "$category_id" != "null" ]]; then
                    categories+=("$category_id")
                    info "  ✓ Encontrada categoría: $category_id"
                fi
            done < <(jq -r '.categories[].id' "$PACKAGES_JSON" 2>/dev/null)
            
            if [[ ${#categories[@]} -eq 0 ]]; then
                error "No se pudieron leer las categorías del JSON"
                info "Verificando archivo JSON..."
                if [[ -f "$PACKAGES_JSON" ]]; then
                    info "📄 Archivo JSON existe: $PACKAGES_JSON"
                    info "🔍 Primeras líneas del JSON:"
                    head -10 "$PACKAGES_JSON"
                else
                    error "❌ Archivo JSON no encontrado: $PACKAGES_JSON"
                fi
                exit 1
            fi
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
        error "🔍 Debug: Modo seleccionado: $install_mode"
        error "📄 JSON utilizado: $PACKAGES_JSON"
        error "📊 Verificando contenido del JSON..."
        
        # Verificar si jq puede leer el archivo
        if jq -r '.categories[].id' "$PACKAGES_JSON" 2>/dev/null | head -5; then
            error "jq puede leer el archivo, pero algo más está mal"
        else
            error "jq no puede leer el archivo JSON correctamente"
        fi
        
        exit 1
    else
        success "✅ Se encontraron ${#categories[@]} categorías: ${categories[*]}"
    fi
        echo
        info "Se instalarán las siguientes categorías: ${categories[*]}"
        if ask_yes_no "¿Continuar con la instalación de paquetes?"; then
            install_packages "$install_mode" "${categories[@]}"
        else
            info "Instalación de paquetes cancelada"
        fi
    fi
    
    # === FASE 2: CONFIGURACIONES ADICIONALES ===
    echo
    info "═══════════════════════════════════════════════════════════════"
    info "                🔧 FASE 2: CONFIGURACIONES                     "
    info "═══════════════════════════════════════════════════════════════"
    
    run_additional_scripts
    run_extra_packages
    
    # === FASE 3: ENLACES SIMBÓLICOS ===
    echo
    info "═══════════════════════════════════════════════════════════════"
    info "                  🔗 FASE 3: ENLACES SIMBÓLICOS                "
    info "═══════════════════════════════════════════════════════════════"
    
    setup_symlinks
    
    # === RESUMEN FINAL ===
    show_final_summary
}

# Manejar señales para limpieza
trap 'error "Instalación interrumpida"; exit 130' INT TERM

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
