#!/bin/bash

# ==============================================================================
# DOTFILES JSON-NATIVE INSTALLER v2.0
# Instalador 100% basado en packages.json - Sin dependencias legacy
# ==============================================================================

set -euo pipefail

# Configuraciones
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"
readonly LOG_DIR="$HOME/.local/share/dotfiles/logs"
readonly STATE_FILE="$HOME/.config/dotfiles/state.json"

# Crear directorios
mkdir -p "$LOG_DIR" "$(dirname "$STATE_FILE")"

# Logging
readonly LOG_FILE="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# Contadores
INSTALLED=0
FAILED=0
SKIPPED=0
TOTAL=0

# ==============================================================================
# FUNCIONES DE UTILIDAD
# ==============================================================================

info() { echo -e "\033[36m[INFO]\033[0m $*" | tee -a "$LOG_FILE"; }
success() { echo -e "\033[32m[✅]\033[0m $*" | tee -a "$LOG_FILE"; }
warning() { echo -e "\033[33m[⚠️]\033[0m $*" | tee -a "$LOG_FILE"; }
error() { echo -e "\033[31m[❌]\033[0m $*" | tee -a "$LOG_FILE"; }

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
║               🚀 DOTFILES JSON-NATIVE INSTALLER v2.0                ║
║                     Arch Linux Package Manager                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
}

ask_yes_no() {
    local prompt="$1"
    while true; do
        read -p "$prompt [s/n]: " yn
        case $yn in
            [Ss]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Por favor, responde con s/n.";;
        esac
    done
}

is_installed() {
    local pkg="$1"
    pacman -Qi "$pkg" >/dev/null 2>&1 || yay -Qi "$pkg" >/dev/null 2>&1
}

# ==============================================================================
# VALIDACIONES Y DEPENDENCIAS
# ==============================================================================

check_system() {
    info "🔍 Verificando sistema..."
    
    # Verificar Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        error "Este script está diseñado para Arch Linux"
        exit 1
    fi
    
    # Verificar JSON
    if [[ ! -f "$PACKAGES_JSON" ]]; then
        error "Archivo packages.json no encontrado: $PACKAGES_JSON"
        exit 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        info "Instalando jq..."
        sudo pacman -S --needed --noconfirm jq
    fi
    
    if ! jq empty "$PACKAGES_JSON" 2>/dev/null; then
        error "El archivo packages.json no es válido"
        exit 1
    fi
    
    success "Sistema válido y listo"
}

install_yay() {
    if command -v yay >/dev/null 2>&1; then
        info "yay ya está instalado"
        return 0
    fi
    
    info "🔧 Instalando yay (AUR helper)..."
    
    # Instalar dependencias
    sudo pacman -S --needed --noconfirm base-devel git
    
    # Clonar e instalar yay
    local temp_dir
    temp_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$temp_dir/yay"
    cd "$temp_dir/yay"
    makepkg -si --noconfirm
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
# SELECCIÓN DE CATEGORÍAS
# ==============================================================================

show_categories() {
    echo
    info "📦 Categorías disponibles en tu configuración:"
    echo
    
    local i=1
    while IFS= read -r category; do
        local id emoji desc packages_count
        id=$(echo "$category" | jq -r '.id')
        emoji=$(echo "$category" | jq -r '.emoji')
        desc=$(echo "$category" | jq -r '.description')
        packages_count=$(echo "$category" | jq '.packages | length')
        
        printf "%2d) %s %s (%d paquetes)\n" "$i" "$emoji" "$id" "$packages_count"
        printf "     └─ %s\n" "$desc"
        echo
        ((i++))
    done < <(jq -c '.categories[]' "$PACKAGES_JSON")
}

select_categories() {
    show_categories
    
    echo "────────────────────────────────────────────────────────────────────────"
    echo "💡 Opciones:"
    echo "   • Números: 1,3,5"
    echo "   • Rangos: 1-5"
    echo "   • Mixto: 1,3-5,8"
    echo "   • 'all' para todas"
    echo "────────────────────────────────────────────────────────────────────────"
    
    local categories=()
    while IFS= read -r id; do
        categories+=("$id")
    done < <(jq -r '.categories[].id' "$PACKAGES_JSON")
    
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
            printf '%s\n' "${selected[@]}"
            return 0
        else
            warning "Selección inválida. Intenta de nuevo."
        fi
    done
}

select_mode() {
    echo
    echo "🔧 Modos de instalación:"
    echo "1) 🚀 Instalación completa (todos los paquetes)"
    echo "2) 📦 Por categorías (seleccionar cuáles)"
    echo "3) 🎯 Selectiva (preguntar cada paquete)"
    echo "4) ⚡ Solo obligatorios (omitir opcionales)"
    echo
    
    while true; do
        read -p "Selecciona modo [1-4]: " mode
        case "$mode" in
            1) echo "full"; return ;;
            2) echo "categories"; return ;;
            3) echo "selective"; return ;;
            4) echo "required_only"; return ;;
            *) echo "Selección inválida. Usa 1-4." ;;
        esac
    done
}

# ==============================================================================
# INSTALACIÓN DE PAQUETES
# ==============================================================================

install_package() {
    local name="$1"
    local repo="$2"
    local optional="$3"
    local mode="$4"
    
    # Ya instalado?
    if is_installed "$name"; then
        info "📦 $name ya está instalado"
        ((SKIPPED++))
        return 0
    fi
    
    # Omitir opcionales en modo required_only
    if [[ "$optional" == "true" ]] && [[ "$mode" == "required_only" ]]; then
        info "⏭️  Omitiendo $name (opcional)"
        ((SKIPPED++))
        return 0
    fi
    
    # Preguntar en modo selectivo
    if [[ "$mode" == "selective" ]]; then
        if ! ask_yes_no "¿Instalar $name?"; then
            info "⏭️  Usuario omitió $name"
            ((SKIPPED++))
            return 0
        fi
    fi
    
    info "🔄 Instalando $name desde $repo..."
    
    # Lógica de instalación: primero pacman, fallback yay
    local success=false
    if [[ "$repo" == "pacman" ]]; then
        if sudo pacman -S --noconfirm "$name" 2>/dev/null; then
            success=true
        else
            info "   Intentando con yay..."
            if yay -S --noconfirm "$name" 2>/dev/null; then
                success=true
            fi
        fi
    else
        # repo == "aur"
        if yay -S --noconfirm "$name" 2>/dev/null; then
            success=true
        fi
    fi
    
    if [[ "$success" == "true" ]]; then
        success "✅ $name instalado"
        ((INSTALLED++))
        return 0
    else
        error "❌ Error instalando $name"
        ((FAILED++))
        return 1
    fi
}

install_category() {
    local category_id="$1"
    local mode="$2"
    
    local category_info
    category_info=$(jq --arg cat "$category_id" '.categories[] | select(.id == $cat)' "$PACKAGES_JSON")
    
    if [[ -z "$category_info" ]] || [[ "$category_info" == "null" ]]; then
        error "Categoría '$category_id' no encontrada"
        return 1
    fi
    
    local emoji desc packages_count
    emoji=$(echo "$category_info" | jq -r '.emoji // "📦"')
    desc=$(echo "$category_info" | jq -r '.description // "Sin descripción"')
    packages_count=$(echo "$category_info" | jq '.packages | length')
    
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    info "🎯 $emoji $category_id ($packages_count paquetes)"
    info "   $desc"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local current=0
    local cat_installed=0
    local cat_failed=0
    local cat_skipped=0
    
    while IFS= read -r package; do
        if [[ -n "$package" ]] && [[ "$package" != "null" ]]; then
            ((current++))
            ((TOTAL++))
            
            local name repo optional desc_pkg
            name=$(echo "$package" | jq -r '.name // ""')
            repo=$(echo "$package" | jq -r '.repo // "pacman"')
            optional=$(echo "$package" | jq -r '.optional // false')
            desc_pkg=$(echo "$package" | jq -r '.description // ""')
            
            if [[ -z "$name" ]]; then
                continue
            fi
            
            printf "[%d/%d] " "$current" "$packages_count"
            if [[ -n "$desc_pkg" ]]; then
                info "📝 $name - $desc_pkg"
            fi
            
            local before_counts="$INSTALLED:$FAILED:$SKIPPED"
            install_package "$name" "$repo" "$optional" "$mode"
            local after_counts="$INSTALLED:$FAILED:$SKIPPED"
            
            # Calcular cambios en esta categoría
            if [[ "$before_counts" != "$after_counts" ]]; then
                if [[ "$INSTALLED" -gt "${before_counts%%:*}" ]]; then
                    ((cat_installed++))
                elif [[ "$FAILED" -gt "${before_counts#*:}" ]]; then
                    ((cat_failed++))
                else
                    ((cat_skipped++))
                fi
            fi
        fi
    done < <(echo "$category_info" | jq -c '.packages[]?')
    
    # Resumen de categoría
    echo
    if [[ $cat_failed -eq 0 ]]; then
        success "✅ $category_id completada"
    else
        warning "⚠️  $category_id completada con errores"
    fi
    echo "   📊 Instalados: $cat_installed | Omitidos: $cat_skipped | Fallidos: $cat_failed"
    echo
}

# ==============================================================================
# FUNCIÓN PRINCIPAL
# ==============================================================================

main() {
    show_banner
    
    check_system
    install_yay
    
    # Actualizar sistema
    info "🔄 Actualizando sistema..."
    sudo pacman -Syu --noconfirm
    
    # Seleccionar modo
    local mode
    mode=$(select_mode)
    
    # Seleccionar categorías
    local categories=()
    case "$mode" in
        "categories")
            while IFS= read -r cat; do
                if [[ -n "$cat" ]]; then
                    categories+=("$cat")
                fi
            done < <(select_categories)
            ;;
        *)
            while IFS= read -r cat; do
                categories+=("$cat")
            done < <(jq -r '.categories[].id' "$PACKAGES_JSON")
            ;;
    esac
    
    if [[ ${#categories[@]} -eq 0 ]]; then
        warning "No se seleccionaron categorías"
        exit 0
    fi
    
    # Confirmar
    echo
    info "Se instalarán ${#categories[@]} categorías en modo: $mode"
    for cat in "${categories[@]}"; do
        local emoji desc
        emoji=$(jq -r --arg c "$cat" '.categories[] | select(.id == $c) | .emoji' "$PACKAGES_JSON")
        desc=$(jq -r --arg c "$cat" '.categories[] | select(.id == $c) | .description' "$PACKAGES_JSON")
        echo "   $emoji $cat - $desc"
    done
    
    if ! ask_yes_no "¿Continuar?"; then
        info "Instalación cancelada"
        exit 0
    fi
    
    # Ejecutar instalación
    echo
    info "🚀 Iniciando instalación..."
    local start_time
    start_time=$(date +%s)
    
    for category in "${categories[@]}"; do
        install_category "$category" "$mode"
    done
    
    local end_time duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # Resumen final
    echo
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                        📊 RESUMEN FINAL                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo
    success "🎉 Instalación completada en ${duration}s"
    echo
    echo "📊 Estadísticas:"
    echo "   ✅ Paquetes instalados: $INSTALLED"
    echo "   ⏭️  Paquetes omitidos: $SKIPPED"
    echo "   ❌ Paquetes fallidos: $FAILED"
    echo "   📦 Total procesados: $TOTAL"
    echo
    echo "📄 Log: $LOG_FILE"
    
    if [[ $FAILED -gt 0 ]]; then
        echo
        warning "⚠️  Algunos paquetes fallaron. Revisa el log para más detalles."
    fi
}

# Manejo de señales
trap 'echo; error "Instalación interrumpida"; exit 130' INT TERM

# Ejecutar
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
