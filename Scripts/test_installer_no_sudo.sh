#!/bin/bash

# Versión de prueba sin sudo para diagnóstico
source /home/deivi/dotfiles-dev/Scripts/full_installer_v2.sh

# Sobrescribir la función install_packages para omitir sudo
install_packages() {
    local install_mode="$1"
    shift
    local categories=("$@")
    
    info "🚀 [PRUEBA] Iniciando instalación de paquetes en modo: $install_mode"
    
    # OMITIR actualización del sistema para la prueba
    info "🔄 [PRUEBA] Omitiendo actualización del sistema..."
    
    # Instalar categorías (solo las primeras 3 para prueba rápida)
    local count=0
    for category in "${categories[@]}"; do
        if [[ $count -ge 3 ]]; then
            info "🔄 [PRUEBA] Limitando a 3 categorías para diagnóstico rápido"
            break
        fi
        install_category "$category" "$install_mode"
        ((count++))
    done
}

# Sobrescribir install_package para simular sin instalación real
install_package() {
    local package="$1"
    local repo_hint="$2"
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
    
    # Preguntar al usuario en modo selectivo (SOLO EN MODO INTERACTIVO)
    if [[ "$install_mode" == "selective" ]]; then
        # Verificar si stdin es un terminal (modo interactivo)
        if [[ -t 0 ]]; then
            echo -n "   🤔 ¿Quieres instalar $package? [s/n]: "
            local response
            while true; do
                read -r response
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
                        echo -n "   ❓ Por favor, responde con s/n: "
                        ;;
                esac
            done
        else
            # Si no es interactivo (pipe), instalar automáticamente en modo selectivo
            info "   🔄 Modo no-interactivo detectado: instalando $package automáticamente"
        fi
    fi
    
    info "   🔄 [PRUEBA] Simulando instalación de $package (hint: $repo_hint)..."
    
    # Simular instalación exitosa
    success "   ✅ [PRUEBA] $package instalado correctamente (simulado)"
    ((TOTAL_INSTALLED++))
    return 0
}

echo "🧪 PRUEBA DE DIAGNÓSTICO SIN SUDO"
echo "═══════════════════════════════════════════════════════════════════"

# Ejecutar solo la lógica de paquetes
main_logic() {
    # Seleccionar categorías según el modo
    local categories=()
    local install_mode="selective"
    
    info "🔍 Leyendo categorías del JSON..."
    while IFS= read -r category_id; do
        if [[ -n "$category_id" ]] && [[ "$category_id" != "null" ]]; then
            categories+=("$category_id")
            info "  ✓ Encontrada categoría: $category_id"
        fi
    done < <(jq -r '.categories[].id' "$PACKAGES_JSON" 2>/dev/null)
    
    if [[ ${#categories[@]} -eq 0 ]]; then
        error "No se pudieron leer las categorías del JSON"
        exit 1
    fi
    
    success "✅ Se encontraron ${#categories[@]} categorías: ${categories[*]}"
    echo
    
    info "🎯 [PRUEBA] MODO SELECTIVO: Se mostrarán todos los paquetes para selección individual"
    info "📋 Categorías a procesar: ${categories[*]}"
    info "💡 Para cada paquete se preguntará: '¿Instalar [paquete]? [s/n]'"
    
    # Procesar paquetes
    install_packages "$install_mode" "${categories[@]}"
}

# Inicializar variables necesarias
PACKAGES_JSON="/home/deivi/dotfiles-dev/Scripts/packages.json"
TOTAL_INSTALLED=0
TOTAL_SKIPPED=0
TOTAL_FAILED=0

# Ejecutar la lógica principal
main_logic
