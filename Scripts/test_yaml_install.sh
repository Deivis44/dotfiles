#!/bin/bash

# Script de prueba para la función install_packages_yaml
readonly PACKAGES_YAML="./packages.yaml"

# Cargar funciones de utilidad del script principal
source ./full_installer_v2.sh

# Solo ejecutar la función de instalación con los primeros 3 paquetes
echo "🧪 Probando install_packages_yaml en modo selective..."

# Simular contadores globales
TOTAL_INSTALLED=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0

# Crear función de prueba que solo procese los primeros 3 paquetes
test_install_packages_yaml() {
    local install_mode="$1"
    
    info "🚀 Iniciando instalación de paquetes en modo: $install_mode"
    echo

    local prev_cat=""
    local count=0
    
    # Obtener lista de categorías y sus paquetes usando yq (solo primeros 3)
    while IFS='|' read -r cat_id cat_desc pkg_name; do
        
        # Limpiar comillas de todos los campos
        cat_id=$(echo "$cat_id" | tr -d '"')
        cat_desc=$(echo "$cat_desc" | tr -d '"')
        pkg_name=$(echo "$pkg_name" | tr -d '"')
        
        # Si es una nueva categoría, mostrar encabezado
        if [[ "$cat_id" != "$prev_cat" ]]; then
            echo
            info "🎯 Categoría: $cat_id"
            echo "   📋 $cat_desc"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            prev_cat="$cat_id"
        fi
        
        echo
        echo "📦 $pkg_name"
        
        # Simular instalación de paquete (solo mostrar, no instalar realmente)
        echo "   🧪 SIMULACIÓN: install_package_simple '$pkg_name' '$install_mode'"
        
        # Incrementar contador y parar después de 3
        ((count++))
        if [[ $count -ge 3 ]]; then
            echo "   🔧 Deteniendo prueba después de $count paquetes..."
            break
        fi
        
    done < <(yq '.categories[] | .id as $cat | .description as $desc | .packages[].name as $pkg | "\($cat)|\($desc)|\($pkg)"' "$PACKAGES_YAML")
    
    echo
    echo "🎯 Prueba completada. Procesados: $count paquetes"
}

# Ejecutar prueba
test_install_packages_yaml "selective"
