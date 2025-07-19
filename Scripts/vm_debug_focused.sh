#!/bin/bash

# ==============================================================================
# SCRIPT DE DEBUG PARA VM - Solo la parte que falla
# ==============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"

echo "🔍 DEBUG DE LA FUNCIÓN QUE FALLA EN VM"
echo "======================================"
echo

# Función exacta del script original con debug
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

echo "📋 Simulando la secuencia exacta del script..."
echo

# Test 1: Función select_installation_mode
echo "🎯 TEST 1: select_installation_mode"
echo "   Simulando selección automática de modo 1..."

# Simular entrada "1"
install_mode=$(echo "1" | select_installation_mode)

echo "   📊 Resultado capturado: '$install_mode'"
echo "   📏 Longitud: ${#install_mode}"
echo "   🔍 Hex dump: $(echo -n "$install_mode" | od -t x1 -A n | tr -d ' ')"

if [[ "$install_mode" == "full" ]]; then
    echo "   ✅ Función funciona correctamente"
else
    echo "   ❌ Función NO funciona: esperado 'full', obtenido '$install_mode'"
    exit 1
fi
echo

# Test 2: Lectura de categorías
echo "🎯 TEST 2: Lectura de categorías para modo '$install_mode'"

if [[ "$install_mode" == "full" ]]; then
    echo "   📝 Ejecutando case \"full\"..."
    
    categories=()
    echo "   🔄 Iniciando bucle while..."
    
    line_count=0
    while IFS= read -r category_id; do
        ((line_count++))
        echo "      📋 Línea $line_count: '$category_id'"
        
        if [[ -n "$category_id" ]] && [[ "$category_id" != "null" ]]; then
            categories+=("$category_id")
            echo "      ✅ Añadida: '$category_id' (total: ${#categories[@]})"
        else
            echo "      ⚠️  Línea vacía o null"
        fi
        
        # Limitar para debug
        if [[ $line_count -ge 5 ]]; then
            echo "      ... (limitando output de debug)"
            break
        fi
    done < <(jq -r '.categories[].id' "$PACKAGES_JSON" 2>/dev/null)
    
    echo "   📊 RESULTADO FINAL:"
    echo "      - Líneas procesadas: $line_count"
    echo "      - Categorías capturadas: ${#categories[@]}"
    
    if [[ ${#categories[@]} -gt 0 ]]; then
        echo "      - Lista: ${categories[*]}"
        echo "   ✅ Lectura exitosa"
    else
        echo "   ❌ Array vacío - ESTE ES EL PROBLEMA"
        
        echo "   🔍 Diagnóstico adicional:"
        echo "      📄 Archivo: $PACKAGES_JSON"
        echo "      📊 Existe: $(test -f "$PACKAGES_JSON" && echo "SÍ" || echo "NO")"
        echo "      📏 Tamaño: $(test -f "$PACKAGES_JSON" && wc -c < "$PACKAGES_JSON" || echo "0") bytes"
        
        echo "      🧪 Test directo de jq:"
        if jq -r '.categories[].id' "$PACKAGES_JSON" 2>/dev/null | head -3; then
            echo "      ✅ jq funciona directamente"
            echo "      ❌ Problema está en el bucle while o la captura"
        else
            echo "      ❌ jq no funciona"
        fi
    fi
else
    echo "   ⏭️  Modo no es 'full', saltando test"
fi

echo
echo "🏁 FIN DEL DEBUG"
echo "================"
