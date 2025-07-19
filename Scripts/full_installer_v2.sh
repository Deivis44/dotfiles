#!/bin/bash

# ==============================================================================
# DOTFILES FULL INSTALLER v2.0 - YAML NATIVE
# Sistema completo unificado - Base de datos YAML única
# ==============================================================================

set -euo pipefail

# Configuraciones globales
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
readonly PACKAGES_YAML="$SCRIPT_DIR/packages.yaml"
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
║                     YAML-Native • Arch Linux                         ║
║                                                                      ║
║   ┌────────────────┬─────────────────────────────────────────────┐   ║
║   │ 📦 Packages    │ YAML-based package management               │   ║
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
        # Force writing the prompt and reading the response from /dev/tty
        echo -n "$prompt [y/N]: " > /dev/tty
        read -r response < /dev/tty
        response="${response:-$default}"
        case "${response,,}" in
            y|yes|s|si) return 0 ;;
            n|no) return 1 ;;
            *) echo "Por favor, responde con y/n (yes/no)" ;;
        esac
    done
}

# Duplicamos /dev/tty en el FD 3 para todas las lecturas interactivas
exec 3<>/dev/tty

ask_select() {
    local pkg="$1" ans
    # Escribe el prompt en fd 3 (la tty), no en stdout
    printf "   🤔 ¿Quieres instalar %s? [s/n]: " "$pkg" >&3
    # Lee la respuesta también de fd 3
    read -r ans <&3
    case "${ans,,}" in
        s|si|y|yes) return 0 ;;
        *)           return 1 ;;
    esac
}

# ==============================================================================
# VALIDACIÓN Y DEPENDENCIAS
# ==============================================================================

check_dependencies() {
    info "🔍 Verificando dependencias del sistema..."

    # Verificar que el sistema esté actualizado
    info "🔄 Verificando actualizaciones del sistema..."
    sudo pacman -Syu --noconfirm || {
        error "❌ Error al actualizar el sistema."
        exit 1
    }
    success "✅ Sistema actualizado correctamente."

    local deps=("yq" "curl" "git" "stow")
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

        # Verificar que se instalaron correctamente
        local still_missing=()
        for dep in "${missing[@]}"; do
            if ! command -v "$dep" >/dev/null 2>&1; then
                still_missing+=("$dep")
            fi
        done

        if [[ ${#still_missing[@]} -gt 0 ]]; then
            error "❌ No se pudieron instalar: ${still_missing[*]}"
            exit 1
        fi

        success "✅ Dependencias instaladas correctamente: ${missing[*]}"
    fi

    # Verificar YAML (ahora que sabemos que yq está disponible)
    if [[ ! -f "$PACKAGES_YAML" ]]; then
        error "Archivo packages.yaml no encontrado en: $PACKAGES_YAML"
        exit 1
    fi

    if ! yq '.' "$PACKAGES_YAML" >/dev/null 2>&1; then
        error "El archivo packages.yaml no es válido"
        info "Verificando sintaxis YAML..."
        yq '.' "$PACKAGES_YAML" 2>&1 | head -10 || true
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
# INSTALACIÓN DE PAQUETES YAML-NATIVE
# ==============================================================================

install_package() {
    local package="$1"
    local repo_hint="$2"      # Solo informativo, NO determinante
    local optional="$3"
    local category="$4"
    local install_mode="$5"

    # Verificar si ya está instalado
    if pacman -Qi "$(echo "$package" | tr '[:upper:]' '[:lower:]')" >/dev/null 2>&1; then
        success "   ✅ $package ya está instalado"
        ((TOTAL_SKIPPED++))
        return 0
    fi

    # Verificar modo de instalación para paquetes opcionales
    if [[ "$optional" == "true" ]] && [[ "$install_mode" == "required_only" ]]; then
        info "   ⏭️  Omitiendo $package (paquete opcional)"
        ((TOTAL_SKIPPED++))
        return 0
    fi

    # Preguntar al usuario en modo selectivo (SOLO EN MODO INTERACTIVO)
    if [[ "$install_mode" == "selective" ]]; then
        echo -n "   🤔 ¿Quieres instalar $package? [s/n]: " > /dev/tty
        local response
        while true; do
            read -r response < /dev/tty
            case "${response,,}" in
                s|si|y|yes)
                    break
                    ;;
                n|no)
                    info "   ⏭️  Usuario omitió $package"
                    ((TOTAL_SKIPPED++))
                    return 2
                    ;;
                *)
                    echo -n "   ❓ Por favor, responde con s/n: " > /dev/tty
                    ;;
            esac
        done
    fi

    info "   🔄 Instalando $package (hint: $repo_hint)..."

    local success_flag=false
    local install_method=""
    local error_log=""

    info "      🔍 Intentando con pacman..."
    if sudo pacman -S --needed --noconfirm "$package" >/dev/null 2>&1; then
        success_flag=true
        install_method="pacman (repositorios oficiales)"
    else
        error_log="pacman falló"

        if command -v yay >/dev/null 2>&1; then
            info "      🔍 Pacman falló, intentando con yay..."
            if yay -S --needed --noconfirm "$package" >/dev/null 2>&1; then
                success_flag=true
                install_method="yay (AUR)"
            else
                error_log="$error_log; yay también falló"
            fi
        else
            error_log="$error_log; yay no disponible"
        fi
    fi

    if [[ "$success_flag" == "true" ]]; then
        success "   ✅ $package instalado correctamente con $install_method"
        ((TOTAL_INSTALLED++))
        return 0
    else
        error "   ❌ Error al instalar $package: $error_log"
        ((TOTAL_FAILED++))
        return 1
    fi
}

install_category() {
    local category_id="$1"
    local install_mode="$2"

    # Obtener emoji, descripción y conteo directamente desde YAML
    local emoji desc packages_count
    emoji=$(yq -r ".categories[] | select(.id == \"${category_id}\") | .emoji // \"📦\"" "$PACKAGES_YAML")
    # Verificar existencia de la categoría
    if [[ -z "$emoji" ]] || [[ "$emoji" == "null" ]]; then
        error "Categoría '$category_id' no encontrada en packages.yaml"
        return 1
    fi
    desc=$(yq -r ".categories[] | select(.id == \"${category_id}\") | .description // \"Sin descripción\"" "$PACKAGES_YAML")
    packages_count=$(yq -r ".categories[] | select(.id == \"${category_id}\") | .packages | length" "$PACKAGES_YAML")

    echo
    info "🎯 Instalando: $emoji $category_id"
    echo "   📋 $desc"
    echo "   📊 $packages_count paquetes en esta categoría"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Pre-cargar nombres y descripciones desde el bloque de la categoría
    local -a pkg_names pkg_descs
    mapfile -t pkg_names < <(
        printf '%s\n' "$category_info" | yq -r '.packages[].name' -
    )
    mapfile -t pkg_descs < <(
        printf '%s\n' "$category_info" | yq -r '.packages[].description // ""' -
    )

    for i in "${!pkg_names[@]}"; do
        local name desc_pkg
        name="${pkg_names[$i]}"
        desc_pkg="${pkg_descs[$i]}"

        echo
        echo "📦 $name — $desc_pkg"

        if [[ "$install_mode" == "selective" ]]; then
            if ask_select "$name"; then
                install_package "$name" "" "false" "$category_id" "$install_mode"
            else
                info "   ⏭️  Omitiendo $name"
                ((TOTAL_SKIPPED++))
            fi
        else
            install_package "$name" "" "false" "$category_id" "$install_mode"
        fi
    done

    info "   ✅ Procesamiento de paquetes completado."
}

select_installation_mode() {
    echo "🔧 Modos de instalación disponibles:" >&2
    echo "1) Instalación completa (todos los paquetes)" >&2
    echo "2) Instalación por categorías" >&2
    echo "3) Instalación selectiva (paquete por paquete)" >&2
    echo "4) Solo paquetes obligatorios" >&2
    echo >&2
    
    while true; do
        read -p "Selecciona un modo [1-4]: " mode
        case "$mode" in
            1) echo "full"; return ;;
            2) echo "categories"; return ;;
            3) echo "selective"; return ;;
            4) echo "required_only"; return ;;
            *) echo "Por favor, selecciona una opción válida (1-4)" >&2 ;;
        esac
    done
}

select_categories() {
    echo >&2
    info "📦 Categorías disponibles:" >&2
    echo >&2
    
    local categories=()
    local i=1
    # Listar id, emoji y descripción en un solo flujo
    while IFS='|' read -r id emoji desc; do
        printf "%2d) %s %s\n" "$i" "$emoji" "$id" >&2
        printf "     └─ %s\n" "$desc" >&2
        echo >&2
        categories+=("$id")
        ((i++))
    done < <(yq -r '.categories[] | .id + "|" + (.emoji // "📦") + "|" + (.description // "Sin descripción")' "$PACKAGES_YAML")
    
    echo "────────────────────────────────────────────────────────────────────────" >&2
    echo "💡 Opciones: números separados por comas (1,3,5), rangos (1-5), o 'all'" >&2
    echo "────────────────────────────────────────────────────────────────────────" >&2
    
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
                    error "Número fuera de rango: $part" >&2
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
                    error "Rango inválido: $part" >&2
                    valid=false
                    break
                fi
            else
                error "Formato inválido: $part" >&2
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
            warning "Selección inválida. Intenta de nuevo." >&2
            echo >&2
        fi
    done
}

install_package_simple() {
    local pkg="$1"
    local install_mode="$2"
    
    # Verificar si ya está instalado
    if pacman -Qi "$pkg" &>/dev/null; then
        success "   ✅ $pkg ya está instalado (omitiendo)"
        ((TOTAL_SKIPPED++))
        return 0
    fi

    # Preguntar al usuario en modo selectivo
    if [[ "$install_mode" == "selective" ]]; then
        while true; do
            read -rp "   🤔 ¿Quieres instalar $pkg? [s/n]: " yn < /dev/tty
            case "${yn,,}" in
                s|si|y|yes) break ;;  # confirmar instalación
                n|no)
                    info "   ⏭️  Usuario omitió $pkg"
                    ((TOTAL_SKIPPED++))
                    return 0    # no abortar al omitir
                    ;;
                *)
                    echo -n "   ❓ Por favor, responde con s/n: " > /dev/tty
                    ;;
            esac
        done
    fi

    info "   🔄 Instalando $pkg..."

    local success_flag=false
    local install_method=""
    local error_log=""

    # Intentar con pacman primero
    if sudo pacman -S --needed --noconfirm "$pkg" &>/dev/null; then
        success_flag=true
        install_method="pacman (repositorios oficiales)"
    else
        error_log="pacman falló"

        # Intentar con yay si está disponible
        if command -v yay >/dev/null 2>&1; then
            if yay -S --needed --noconfirm "$pkg" &>/dev/null; then
                success_flag=true
                install_method="yay (AUR)"
            else
                error_log="$error_log; yay también falló"
            fi
        else
            error_log="$error_log; yay no disponible"
        fi
    fi

    if [[ "$success_flag" == "true" ]]; then
        success "   ✅ $pkg instalado correctamente con $install_method"
        ((TOTAL_INSTALLED++))
        return 0
    else
        error "   ❌ Error al instalar $pkg: $error_log"
        ((TOTAL_FAILED++))
        return 1
    fi
}

install_packages_yaml() {
    local install_mode="$1"
    info "🚀 Iniciando instalación de paquetes en modo: $install_mode"
    echo

    # 1) Pre-cargar todas las entradas CATEGORY|DESCRIPTION|PKG en un array
    mapfile -t pkg_entries < <(
        yq -r '.categories[] | .id as $cat | .description as $desc | .packages[].name as $pkg | "\($cat)|\($desc)|\($pkg)"' "$PACKAGES_YAML"
    )

    # 2) Iterar en el shell principal para mantener stdin intacto
    local prev_cat=""
    for entry in "${pkg_entries[@]}"; do
        IFS='|' read -r cat_id cat_desc pkg_name <<<"$entry"
        # Mostrar header solo una vez por categoría
        if [[ "$cat_id" != "$prev_cat" ]]; then
            echo
            info "🎯 Categoría: $cat_id"
            echo "   📋 $cat_desc"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            prev_cat="$cat_id"
        fi
        # Instalar cada paquete individualmente
        echo "📦 $pkg_name"
        install_package_simple "$pkg_name" "$install_mode" || true  # no abort on skip or error
    done
}

install_packages() {
    local install_mode="$1"
    shift
    local categories=("${@}")
    
    # Usar la nueva función YAML directamente
    install_packages_yaml "$install_mode"
}

# Instalar paquetes solo de categorías seleccionadas usando lógica de full-mode (por categorías)
install_selected_categories() {
    local install_mode="$1"
    shift
    local categories=("$@")
    info "🚀 Iniciando instalación por categorías seleccionadas: ${categories[*]}"
    echo
    for cat in "${categories[@]}"; do
        # Obtener descripción de la categoría
        local desc
        desc=$(yq -r ".categories[] | select(.id == \"${cat}\") | .description // \"Sin descripción\"" "$PACKAGES_YAML")
        # Cargar lista de paquetes
        mapfile -t pkgs < <(
            yq -r ".categories[] | select(.id == \"${cat}\") | .packages[].name" "$PACKAGES_YAML"
        )
        echo
        info "🎯 Categoría: $cat"
        echo "   📋 $desc"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        for pkg in "${pkgs[@]}"; do
            echo "📦 $pkg"
            install_package_simple "$pkg" "$install_mode" || true
        done
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
# VISTA PREVIA DE PAQUETES
# ==============================================================================
show_packages_preview() {
    local categories=("${@}")
    echo
    info "🔍 Vista previa de paquetes por categoría:"  
    for cat in "${categories[@]}"; do
        echo
        info "📁 $cat"
        # Cargar nombres de paquetes en array
        mapfile -t pkgs < <(
            yq -r ".categories[] | select(.id == \"$cat\") | .packages[].name" "$PACKAGES_YAML"
        )
        echo "   Paquetes (${#pkgs[@]}):"
        for pkg in "${pkgs[@]}"; do
            echo "     - $pkg"
        done
    done
    echo
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
    
    # === PRE-VERIFICACIÓN: DIAGNÓSTICO DEL SISTEMA ===
    echo
    info "═══════════════════════════════════════════════════════════════"
    info "              🔍 PRE-VERIFICACIÓN DEL SISTEMA                   "
    info "═══════════════════════════════════════════════════════════════"
    
    # Ejecutar diagnóstico rápido
    local diagnostic_script="$SCRIPT_DIR/system_diagnostic.sh"
    if [[ -f "$diagnostic_script" ]]; then
        info "🔍 Ejecutando diagnóstico automático del sistema..."
        if bash "$diagnostic_script" auto; then
            success "✅ Sistema verificado y preparado correctamente"
        else
            error "❌ Se encontraron problemas en el sistema"
            warning "Revisa el output anterior antes de continuar"
            if ! ask_yes_no "¿Continuar de todas formas?"; then
                info "Instalación cancelada por el usuario"
                exit 1
            fi
        fi
    else
        warning "Script de diagnóstico no encontrado, continuando sin verificación previa"
    fi
    
    # Verificaciones iniciales (ahora mejoradas)
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
            info "🔍 Leyendo categorías del YAML..."
            while IFS= read -r category_id; do
                if [[ -n "$category_id" ]] && [[ "$category_id" != "null" ]]; then
                    categories+=("$category_id")
                    info "  ✓ Encontrada categoría: $category_id"
                fi
            done < <(yq '.categories[].id' "$PACKAGES_YAML" 2>/dev/null)
            
            if [[ ${#categories[@]} -eq 0 ]]; then
                error "No se pudieron leer las categorías del YAML"
                info "Verificando archivo YAML..."
                if [[ -f "$PACKAGES_YAML" ]]; then
                    info "📄 Archivo YAML existe: $PACKAGES_YAML"
                    info "🔍 Primeras líneas del YAML:"
                    head -10 "$PACKAGES_YAML"
                else
                    error "❌ Archivo YAML no encontrado: $PACKAGES_YAML"
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
        error "📄 YAML utilizado: $PACKAGES_YAML"
        error "📊 Verificando contenido del YAML..."
        # Verificar si yq puede leer las categorías
        if yq -r '.categories[].id' "$PACKAGES_YAML" 2>/dev/null | head -5; then
            error "yq puede leer el archivo, pero algo más está mal"
        else
            error "yq no puede leer el archivo YAML correctamente"
        fi
        
        exit 1
    else
        success "✅ Se encontraron ${#categories[@]} categorías: ${categories[*]}"
        echo
        
        # Mostrar mensaje diferente según el modo de instalación
        case "$install_mode" in
            "full")
                info "🚀 MODO COMPLETO: Se instalarán TODOS los paquetes de todas las categorías automáticamente"
                # Contar paquetes desde YAML
                local total_packages
                total_packages=$(yq -r '[.categories[].packages | length] | add' "$PACKAGES_YAML")
                info "📊 Total estimado: $total_packages paquetes"
                if ask_yes_no "⚠️  ¿Continuar con la instalación completa automática?"; then
                    install_packages "$install_mode" "${categories[@]}"
                else
                    info "Instalación cancelada"
                fi
                ;;
            "selective")
                info "🎯 MODO SELECTIVO: Se mostrarán todos los paquetes para selección individual"
                info "📋 Categorías a procesar: ${categories[*]}"
                info "💡 Para cada paquete se preguntará: '¿Instalar [paquete]? [s/n]'"
                # In selective mode, proceed directly
                install_packages "$install_mode" "${categories[@]}"
                ;;
            "required_only")
                local required_count=$(jq '[.categories[].packages[] | select(.optional == false or .optional == null)] | length' "$PACKAGES_JSON")
                local optional_count=$(jq '[.categories[].packages[] | select(.optional == true)] | length' "$PACKAGES_JSON")
                info "📦 MODO REQUERIDOS: Se instalarán solo los paquetes marcados como obligatorios"
                info "✅ Paquetes obligatorios: $required_count"
                info "⏭️  Paquetes opcionales (omitidos): $optional_count"
                if ask_yes_no "¿Continuar con la instalación de paquetes obligatorios?"; then
                    install_packages "$install_mode" "${categories[@]}"
                else
                    info "Instalación cancelada"
                fi
                ;;
            "categories")
                info "📁 MODO CATEGORÍAS: Se instalarán TODOS los paquetes de las categorías seleccionadas"
                info "🎯 Categorías seleccionadas: ${categories[*]}"
                # Mostrar vista previa de paquetes
                show_packages_preview "${categories[@]}"
                if ask_yes_no "¿Continuar con la instalación de las categorías seleccionadas?"; then
                    install_selected_categories "$install_mode" "${categories[@]}"
                else
                    info "Instalación cancelada"
                fi
                ;;    
        esac
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
