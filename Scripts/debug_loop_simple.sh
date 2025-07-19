#!/bin/bash

echo "🔍 DEBUG: Probando el loop específico del problema"
echo "═══════════════════════════════════════════════════════════════"

# Variables para simular el entorno
PACKAGES_JSON="/home/deivi/dotfiles-dev/Scripts/packages.json"
category_id="1. DOTFILES"

# Obtener información de la categoría como lo hace el instalador
category_info=$(jq --arg cat "$category_id" '.categories[] | select(.id == $cat)' "$PACKAGES_JSON")

echo "📋 Información de categoría obtenida:"
echo "$category_info" | jq '.'

echo
echo "📊 Probando el loop problemático:"

current=0
while IFS= read -r package_info <&3; do
    echo "🔍 Loop iteration: package_info = '$package_info'"
    
    if [[ -n "$package_info" ]] && [[ "$package_info" != "null" ]]; then
        ((current++))
        echo "   ✅ Procesando paquete $current"
        
        local name
        name=$(echo "$package_info" | jq -r '.name // ""')
        echo "   📦 Nombre: $name"
    else
        echo "   ❌ Paquete vacío o nulo"
    fi
done 3< <(echo "$category_info" | jq -c '.packages[]?')

echo
echo "📊 Resultado del loop:"
echo "   • Total procesados: $current"

if [[ $current -eq 0 ]]; then
    echo "   ❌ El loop no procesó ningún paquete - hay un problema"
    echo
    echo "🔍 Debugging adicional:"
    echo "   • ¿El jq produce salida?"
    echo "$category_info" | jq -c '.packages[]?' | wc -l
    echo "   • Primera línea de salida de jq:"
    echo "$category_info" | jq -c '.packages[]?' | head -1
else
    echo "   ✅ El loop funcionó correctamente"
fi
