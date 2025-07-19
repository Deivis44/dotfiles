#!/bin/bash

# Script de prueba para verificar la iteración YAML
PACKAGES_YAML="./packages.yaml"

echo "🔍 Probando iteración de paquetes por categoría..."
echo

echo "=== MÉTODO 1: Separando categoría y paquete ==="
prev_cat=""
while IFS='|' read -r cat_id cat_desc pkg_name; do
    # Limpiar comillas
    cat_id=$(echo "$cat_id" | tr -d '"')
    cat_desc=$(echo "$cat_desc" | tr -d '"')
    pkg_name=$(echo "$pkg_name" | tr -d '"')
    
    # Si es una nueva categoría, mostrar encabezado
    if [[ "$cat_id" != "$prev_cat" ]]; then
        echo
        echo "🎯 Categoría: $cat_id"
        echo "   📋 $cat_desc"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        prev_cat="$cat_id"
    fi
    
    echo "📦 $pkg_name"
    
done < <(yq '.categories[] | .id as $cat | .description as $desc | .packages[].name as $pkg | "\($cat)|\($desc)|\($pkg)"' "$PACKAGES_YAML" | head -10)

echo
echo "=== MÉTODO 2: Iterando categorías primero ==="
yq '.categories[0:3][] | .id' "$PACKAGES_YAML" | while read -r category; do
    category=$(echo "$category" | tr -d '"')
    echo
    echo "🎯 Categoría: $category"
    description=$(yq --arg cat "$category" '.categories[] | select(.id == $cat) | .description' "$PACKAGES_YAML" | tr -d '"')
    echo "   📋 $description"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    yq --arg cat "$category" '.categories[] | select(.id == $cat) | .packages[].name' "$PACKAGES_YAML" | while read -r package; do
        package=$(echo "$package" | tr -d '"')
        echo "   📦 $package"
    done
done

echo
echo "=== MÉTODO 3: Solo primeros 5 paquetes para debug ==="
yq '.categories[0].packages[0:5][].name' "$PACKAGES_YAML" | while read -r package; do
    package=$(echo "$package" | tr -d '"')
    echo "📦 $package"
done
