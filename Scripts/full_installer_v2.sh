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

    # Forzar entrada y salida desde el terminal real
    while true; do
        echo -n "$prompt [y/N]: " > /dev/tty
        read -r response < /dev/tty
        response="${response:-$default}"
        case "${response,,}" in
            y|yes|s|si) return 0 ;;
            n|no)       return 1 ;;
            *)          echo "Por favor, responde con y/n (yes/no)" >&2 ;;
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
    
    # Verificar JSON (ahora que sabemos que jq está disponible)
    if [[ ! -f "$PACKAGES_JSON" ]]; then
        error "Archivo packages.json no encontrado en: $PACKAGES_JSON"
        exit 1
    fi
    
    if ! jq empty "$PACKAGES_JSON" 2>/dev/null; then
        error "El archivo packages.json no es válido"
        info "Verificando sintaxis JSON..."
        jq . "$PACKAGES_JSON" 2>&1 | head -10 || true
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
    local repo_hint="$2"      # Solo informativo, NO determinante
    local optional="$3"
    local category="$4"
    local install_mode="$5"
    
    # Verificar si ya está instalado
    if pacman -Qi "$package" >/dev/null 2>&1; then
        success "   ✅ $package ya está instalado"
        ((TOTAL_SKIPPED++))
        return 0
    fi
    
    # Verificar modo de instalación para paquetes opcionales
    if [[ "$optional" == "true" ]] && [[ "$install_mode" == "required_only" ]]; then
        info "   ⏭️  Omitiendo $package (paquete opcional)"
        ((TOTAL_SKIPPED++))
        return 2
    fi
    
    # Preguntar al usuario en modo selectivo
    if [[ "$install_mode" == "selective" ]]; then
        info "   🔍 DEBUG: Preguntando al usuario si desea instalar $package..."
        if ! ask_yes_no "   🤔 ¿Quieres instalar $package?"; then
            info "   ⏭️  Usuario omitió $package"
            ((TOTAL_SKIPPED++))
            info "   🔍 DEBUG: Usuario decidió no instalar $package."
            return 2
        fi
        info "   🔍 DEBUG: Usuario decidió instalar $package."
    fi
    
    info "   🔄 Instalando $package (hint: $repo_hint)..."
    
    # ============================================================================
    # LÓGICA INTELIGENTE: SIEMPRE PROBAR PACMAN PRIMERO, LUEGO YAY
    # El campo "repo" del JSON es solo informativo, no determinante
    # ============================================================================
    
    local success_flag=false
    local install_method=""
    local error_log=""
    
    # PASO 1: Intentar con pacman (repositorios oficiales)
    info "      🔍 Intentando con pacman..."
    if sudo pacman -S --needed --noconfirm "$package" >/dev/null 2>&1; then
        success_flag=true
        install_method="pacman (repositorios oficiales)"
    else
        error_log="pacman falló"
        
        # PASO 2: Si pacman falla, intentar con yay (AUR)
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
    # Vista previa de paquetes en esta categoría
    info "   🔍 Paquetes en $category_id:"
    for pkg in $(echo "$category_info" | jq -r '.packages[].name'); do
        echo "     - $pkg"
    done
    echo
    
    # Instalar paquetes - PROCESO MEJORADO
    local current=0
    local category_installed=0
    local category_failed=0
    local category_skipped=0
    
    info "   🔄 Iniciando procesamiento de paquetes..."
    
    # Debug: verificar que tenemos paquetes
    local package_count_check
    package_count_check=$(echo "$category_info" | jq '.packages | length')
    info "   📊 Verificación: $package_count_check paquetes detectados"
    
    # Debug: verificar que el comando jq funciona
    info "   🔍 Debug: Iniciando loop de procesamiento..."
    
    # Validar que category_info contiene datos válidos
    if [[ -z "$category_info" ]] || [[ "$category_info" == "null" ]]; then
        error "Categoría '$category_id' no encontrada o inválida en packages.json"
        return 1
    fi

    # Validar que jq puede procesar los paquetes
    if ! echo "$category_info" | jq -e '.packages[]' >/dev/null 2>&1; then
        error "Error al procesar paquetes en la categoría '$category_id'"
        return 1
    fi

    # Usar un file descriptor diferente para evitar conflictos con stdin del pipe
    while IFS= read -r package_info <&3; do
        if [[ -z "$package_info" ]] || [[ "$package_info" == "null" ]]; then
            warning "   ⚠️  Paquete vacío o nulo encontrado, omitiendo..."
            continue
        fi

        info "   🔍 DEBUG: Leyendo package_info: $(echo "$package_info" | jq -c '.')"

        if [[ -n "$package_info" ]] && [[ "$package_info" != "null" ]]; then
            ((current++))
            info "   🔍 Procesando paquete $current de $packages_count..."

            local name repo optional desc_pkg
            name=$(echo "$package_info" | jq -r '.name // ""')
            repo=$(echo "$package_info" | jq -r '.repo // "pacman"')
            optional=$(echo "$package_info" | jq -r '.optional // false')
            desc_pkg=$(echo "$package_info" | jq -r '.description // ""')

            if [[ -z "$name" ]]; then
                warning "Paquete sin nombre encontrado, omitiendo..."
                continue
            fi

            # Mostrar progreso mejorado
            echo
            printf "📦 [%d/%d] %s" "$current" "$packages_count" "$name" > /dev/tty
            if [[ -n "$desc_pkg" ]]; then
                printf " - %s" "$desc_pkg" > /dev/tty
            fi
            echo > /dev/tty

            # Resultado de la instalación con contadores locales
            # Usar || para capturar el código de retorno sin activar set -e
            local install_result=0
            install_package "$name" "$repo" "$optional" "$category_id" "$install_mode" || install_result=$?

            case $install_result in
                0) ((category_installed++)) ;;
                1) ((category_failed++)) ;;
                2) ((category_skipped++)) ;;
            esac
        else
            warning "   ⚠️  Paquete vacío o nulo encontrado, omitiendo..."
            info "   🔍 DEBUG: package_info vacío: '$package_info'"
        fi
    done 3< <(echo "$category_info" | jq -c '.packages[]')
    info "   🔍 DEBUG: Procesando paquetes sin operador '?' en jq."
    
    info "   🔍 DEBUG: Terminó el loop while. Paquetes procesados: $current"
    info "   ✅ Procesamiento de paquetes completado. Procesados: $current"
    
    # Resumen de la categoría
    echo
    echo "───────────────────────────────────────────────────────────────"
    info "📊 Resumen de $category_id:"
    info "   ✅ Instalados: $category_installed"
    info "   ❌ Fallidos: $category_failed"
    info "   ⏭️  Omitidos: $category_skipped"
    echo "───────────────────────────────────────────────────────────────"
    echo
    info "🔄 Continuando con la siguiente categoría..."
    echo
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
    
    while IFS= read -r category_line; do
        local id emoji desc
        id=$(echo "$category_line" | jq -r '.id')
        emoji=$(echo "$category_line" | jq -r '.emoji')
        desc=$(echo "$category_line" | jq -r '.description')
        
        printf "%2d) %s %s\n" "$i" "$emoji" "$id" >&2
        printf "     └─ %s\n" "$desc" >&2
        echo >&2
        
        categories+=("$id")
        ((i++))
    done < <(jq -c '.categories[]' "$PACKAGES_JSON")
    
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

generate_package_list() {
    local package_list
    package_list=$(jq -c '[.categories[] | {category: .id, packages: .packages}]' "$PACKAGES_JSON")
    echo "$package_list"
}

install_packages() {
    local install_mode="$1"
    shift
    local categories=($(generate_package_list))

    info "🚀 Iniciando instalación de paquetes en modo: $install_mode"

    for category_info in "${categories[@]}"; do
        local category_name
        local packages
        category_name=$(echo "$category_info" | jq -r '.category')
        packages=$(echo "$category_info" | jq -c '.packages')

        info "🎯 Instalando categoría: $category_name"
        for package_info in $(echo "$packages" | jq -c '.[]'); do
            local name repo optional desc_pkg
            name=$(echo "$package_info" | jq -r '.name')
            repo=$(echo "$package_info" | jq -r '.repo')
            optional=$(echo "$package_info" | jq -r '.optional')
            desc_pkg=$(echo "$package_info" | jq -r '.description')

            if [[ "$install_mode" == "selective" ]]; then
                info "   🔍 Preguntando al usuario si desea instalar $name..."
                if ! ask_yes_no "   🤔 ¿Quieres instalar $name?"; then
                    info "   ⏭️  Usuario omitió $name"
                    continue
                fi
            fi

            info "   🔄 Instalando $name (repo: $repo)..."
            install_package "$name" "$repo" "$optional" "$category_name" "$install_mode"
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
            if bash "$stow_script" ]; then
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
        # Obtener lista de nombres de paquetes
        local pkgs
        pkgs=$(jq --arg cat "$cat" -r '.categories[] | select(.id == $cat) | .packages[].name' "$PACKAGES_JSON")
        echo
        info "📁 $cat"  
        echo "   Paquetes (${#pkgs[@]}):"
        while IFS= read -r pkg; do
            echo "     - $pkg"
        done <<< "$pkgs"
    done
    echo
}

# ==============================================================================
# RESUMEN FINAL
# ==============================================================================

show_final_summary() {
    echo
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    🎉 INSTALACIÓN COMPLETADA                         ║"
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

    # Actualizar sistema ANTES de la instalación de paquetes
    info "🔄 Actualizando sistema antes de instalar paquetes..."
    sudo pacman -Syu --noconfirm

    # === OPCIÓN DE DEPURACIÓN ===
    echo
    info "═══════════════════════════════════════════════════════════════"
    info "              🔍 OPCIÓN DE DEPURACIÓN                          "
    info "═══════════════════════════════════════════════════════════════"

    if ask_yes_no "¿Deseas generar y ver el diccionario de depuración desde el JSON?"; then
        generate_debug_dictionary
        exit 0
    fi

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
        success "✅ Se encontraron ${#categories[@]} categorías:"
        for cat in "${categories[@]}"; do
            echo "   • $cat"
        done
        echo
        
        # Mostrar mensaje diferente según el modo de instalación
        case "$install_mode" in
            "full")
                info "🚀 MODO COMPLETO: Se instalarán TODOS los paquetes de todas las categorías automáticamente"
                info "📊 Total estimado: $(jq '[.categories[].packages | length] | add' "$PACKAGES_JSON") paquetes"
                if ask_yes_no "⚠️  ¿Continuar con la instalación completa automática?"; then
                    install_packages "$install_mode" "${categories[@]}"
                else
                    info "Instalación cancelada"
                fi
                ;;
            "selective")
                info "🎯 MODO SELECTIVO: Se mostrarán todos los paquetes para selección individual"
                echo "📋 Categorías a procesar:"
                for cat in "${categories[@]}"; do
                    echo "   • $cat"
                done
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
                local selected_count=0
                for cat in "${categories[@]}"; do
                    local cat_count=$(jq --arg cat "$cat" '.categories[] | select(.id == $cat) | .packages | length' "$PACKAGES_JSON")
                    selected_count=$((selected_count + cat_count))
                done
                info "📊 Total de paquetes en categorías seleccionadas: $selected_count"
                if ask_yes_no "¿Continuar con la instalación de las categorías seleccionadas?"; then
                    install_packages "$install_mode" "${categories[@]}"
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

generate_debug_dictionary() {
    local debug_dict
    debug_dict=$(jq -c '[.categories[] | {category: .id, packages: [.packages[] | {name: .name, repo: .repo, optional: .optional, description: .description}]}]' "$PACKAGES_JSON")

    if [[ -z "$debug_dict" ]]; then
        error "No se pudo generar el diccionario desde el JSON"
        return 1
    fi

    info "📋 Diccionario generado desde el JSON:"
    echo "$debug_dict" | jq '.'
    return 0
}

# Manejar señales para limpieza
trap 'error "Instalación interrumpida"; exit 130' INT TERM

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
