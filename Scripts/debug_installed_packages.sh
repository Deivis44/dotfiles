#!/bin/bash

echo "🔍 DIAGNÓSTICO: Paquetes ya instalados en modo selectivo"
echo "══════════════════════════════════════════════════════════════════"

# Simular el comportamiento exacto del instalador cuando encuentra paquetes instalados
PACKAGES_JSON="/home/deivi/dotfiles-dev/Scripts/packages.json"

# Función para verificar si un paquete está instalado
is_package_installed() {
    local package="$1"
    if pacman -Qi "$package" >/dev/null 2>&1; then
        return 0  # Instalado
    else
        return 1  # No instalado
    fi
}

# Simular la función install_package del instalador
simulate_install_package() {
    local package="$1"
    local install_mode="$2"
    
    echo "📦 Procesando paquete: $package"
    
    # Verificar si ya está instalado
    if is_package_installed "$package"; then
        echo "   ✅ $package ya está instalado"
        return 0
    fi
    
    # Si no está instalado y es modo selectivo, preguntar
    if [[ "$install_mode" == "selective" ]]; then
        echo -n "   🤔 ¿Quieres instalar $package? [s/n]: "
        local response
        read -r response
        case "${response,,}" in
            s|si|y|yes) 
                echo "   🔄 Instalando $package..."
                return 0
                ;;
            n|no) 
                echo "   ⏭️  Usuario omitió $package"
                return 2
                ;;
        esac
    fi
}

# Simular la función install_category
simulate_install_category() {
    local category_id="$1"
    local install_mode="$2"
    
    # Obtener información de la categoría
    local category_info
    category_info=$(jq --arg cat "$category_id" '.categories[] | select(.id == $cat)' "$PACKAGES_JSON")
    
    if [[ -z "$category_info" ]] || [[ "$category_info" == "null" ]]; then
        echo "❌ Categoría '$category_id' no encontrada"
        return 1
    fi
    
    local emoji desc packages_count
    emoji=$(echo "$category_info" | jq -r '.emoji // "📦"')
    desc=$(echo "$category_info" | jq -r '.description // "Sin descripción"')
    packages_count=$(echo "$category_info" | jq '.packages | length')
    
    echo
    echo "🎯 Procesando: $emoji $category_id"
    echo "   📋 $desc"
    echo "   📊 $packages_count paquetes en esta categoría"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Vista previa de paquetes
    echo "   🔍 Paquetes en $category_id:"
    for pkg in $(echo "$category_info" | jq -r '.packages[].name'); do
        echo "     - $pkg"
    done
    echo
    
    echo "   🔄 Iniciando procesamiento de paquetes..."
    
    # Procesar cada paquete
    local current=0
    local category_installed=0
    local category_skipped=0
    
    while IFS= read -r package_info; do
        if [[ -n "$package_info" ]] && [[ "$package_info" != "null" ]]; then
            ((current++))
            echo "   🔍 Procesando paquete $current de $packages_count..."
            
            local name
            name=$(echo "$package_info" | jq -r '.name // ""')
            
            if [[ -z "$name" ]]; then
                echo "   ⚠️  Paquete sin nombre, omitiendo..."
                continue
            fi
            
            echo
            echo "📦 [$current/$packages_count] $name"
            
            # Llamar a la función de instalación simulada
            local install_result
            simulate_install_package "$name" "$install_mode"
            install_result=$?
            
            case $install_result in
                0) ((category_installed++)) ;;
                2) ((category_skipped++)) ;;
            esac
            
            echo "   📊 Resultado: código $install_result"
        fi
    done < <(echo "$category_info" | jq -c '.packages[]?')
    
    echo
    echo "   ✅ Procesamiento completado. Procesados: $current"
    echo
    echo "───────────────────────────────────────────────────────────────"
    echo "📊 Resumen de $category_id:"
    echo "   ✅ Instalados: $category_installed"
    echo "   ⏭️  Omitidos: $category_skipped"
    echo "───────────────────────────────────────────────────────────────"
    echo
    echo "🔄 Continuando con la siguiente categoría..."
    echo
    
    return 0
}

echo "🧪 PRUEBA 1: Modo selectivo con primera categoría"
echo "─────────────────────────────────────────────────────"
simulate_install_category "1. DOTFILES" "selective"

echo
echo "🧪 PRUEBA 2: Continuando con segunda categoría"
echo "─────────────────────────────────────────────────────"
simulate_install_category "2. CORE_SYSTEM" "selective"

echo
echo "✅ PRUEBA COMPLETADA"
echo "💡 Si ves este mensaje, el flujo funciona correctamente"
