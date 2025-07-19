#!/bin/bash

# ==============================================================================
# DEBUG ESPECÍFICO PARA VM - Diagnóstico completo
# ==============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"

echo "🔍 DEBUG ESPECÍFICO PARA VM"
echo "============================"
echo

# 1. Información del entorno
echo "📋 INFORMACIÓN DEL ENTORNO:"
echo "   Sistema: $(uname -a)"
echo "   Usuario: $(whoami)"
echo "   Shell: $SHELL"
echo "   PWD: $(pwd)"
echo "   SCRIPT_DIR: $SCRIPT_DIR"
echo "   PACKAGES_JSON: $PACKAGES_JSON"
echo

# 2. Verificar herramientas críticas
echo "🔧 HERRAMIENTAS CRÍTICAS:"
for tool in bash jq head cat ls; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "   ✅ $tool: $(which "$tool") - $(${tool} --version 2>/dev/null | head -1 || echo 'Version no disponible')"
    else
        echo "   ❌ $tool: NO ENCONTRADO"
    fi
done
echo

# 3. Verificar archivo JSON
echo "📄 VERIFICACIÓN DEL ARCHIVO JSON:"
echo "   Existe: $(test -f "$PACKAGES_JSON" && echo "✅ SÍ" || echo "❌ NO")"
if [[ -f "$PACKAGES_JSON" ]]; then
    echo "   Tamaño: $(wc -c < "$PACKAGES_JSON") bytes"
    echo "   Líneas: $(wc -l < "$PACKAGES_JSON")"
    echo "   Permisos: $(ls -la "$PACKAGES_JSON")"
    echo "   Propietario: $(stat -c "%U:%G" "$PACKAGES_JSON")"
    echo "   Readable: $(test -r "$PACKAGES_JSON" && echo "✅ SÍ" || echo "❌ NO")"
fi
echo

# 4. Test de validez JSON
echo "🧪 TEST DE VALIDEZ JSON:"
if [[ -f "$PACKAGES_JSON" ]]; then
    if jq empty "$PACKAGES_JSON" 2>/dev/null; then
        echo "   ✅ JSON es válido"
        
        # Verificar estructura
        if jq -e '.categories' "$PACKAGES_JSON" >/dev/null 2>&1; then
            categories_count=$(jq '.categories | length' "$PACKAGES_JSON")
            echo "   ✅ Estructura válida: $categories_count categorías"
        else
            echo "   ❌ Estructura inválida: falta '.categories'"
        fi
    else
        echo "   ❌ JSON NO es válido"
        echo "   📋 Error de jq:"
        jq . "$PACKAGES_JSON" 2>&1 | head -5 || echo "   Error al parsear JSON"
    fi
else
    echo "   ❌ No se puede verificar: archivo no existe"
fi
echo

# 5. Test del comando exacto que falla
echo "🎯 TEST DEL COMANDO EXACTO:"
echo "   Comando: jq -r '.categories[].id' \"\$PACKAGES_JSON\""

# Método 1: Captura directa
echo "   📝 Método 1 - Salida directa:"
if jq -r '.categories[].id' "$PACKAGES_JSON" 2>/dev/null | head -5; then
    echo "   ✅ Método 1 funciona"
else
    echo "   ❌ Método 1 falla"
fi

# Método 2: Simulación exacta del script
echo "   📝 Método 2 - Simulación exacta del bucle:"
categories=()
count=0
while IFS= read -r category_id; do
    if [[ -n "$category_id" ]] && [[ "$category_id" != "null" ]]; then
        categories+=("$category_id")
        echo "      ✓ Categoría $((++count)): '$category_id'"
    else
        echo "      ⚠️  Línea problemática: '$category_id'"
    fi
    
    # Limitar output para debug
    if [[ $count -ge 5 ]]; then
        echo "      ... (mostrando solo primeras 5)"
        break
    fi
done < <(jq -r '.categories[].id' "$PACKAGES_JSON" 2>/dev/null)

echo "   📊 Resultado: ${#categories[@]} categorías capturadas"
if [[ ${#categories[@]} -gt 0 ]]; then
    echo "   ✅ Array poblado: ${categories[*]}"
else
    echo "   ❌ Array VACÍO"
fi
echo

# 6. Test de redirección stderr
echo "🔀 TEST DE REDIRECCIÓN:"
echo "   📝 Verificando si hay interferencia en stderr..."

# Simular exactamente como el script original
test_mode() {
    echo "full"
}

# Capturar exactamente como el script
echo "   📝 Simulando select_installation_mode():"
install_mode=$(test_mode)
echo "   📊 Modo capturado: '$install_mode'"

if [[ "$install_mode" == "full" ]]; then
    echo "   ✅ Captura de modo funciona"
else
    echo "   ❌ Captura de modo falla: esperado 'full', obtenido '$install_mode'"
fi
echo

# 7. Test de dependencias del shell
echo "🐚 TEST DE SHELL Y DEPENDENCIAS:"
echo "   Bash version: ${BASH_VERSION:-N/A}"
echo "   Set options: $-"
echo "   IFS: '$IFS'"
echo "   Test de arrays:"

test_array=("uno" "dos" "tres")
echo "   Array test: ${#test_array[@]} elementos"
echo "   Elementos: ${test_array[*]}"
echo

# 8. Diagnosis final
echo "🏁 DIAGNÓSTICO FINAL:"
if [[ -f "$PACKAGES_JSON" ]] && jq empty "$PACKAGES_JSON" 2>/dev/null; then
    if jq -r '.categories[].id' "$PACKAGES_JSON" 2>/dev/null | head -1 >/dev/null; then
        echo "   ✅ Archivo JSON funciona correctamente"
        echo "   🔍 Posibles causas del fallo en script principal:"
        echo "      - Problema de captura en \$(select_installation_mode)"
        echo "      - Interferencia de stdout/stderr"
        echo "      - Variables de entorno diferentes"
        echo "      - Configuración de shell diferente"
    else
        echo "   ❌ jq no puede leer las categorías"
    fi
else
    echo "   ❌ Problema fundamental con JSON o jq"
fi

echo
echo "💡 PRÓXIMOS PASOS RECOMENDADOS:"
echo "   1. Ejecuta este script en la VM: ./vm_debug.sh"
echo "   2. Compara resultados con este entorno"
echo "   3. Instala herramientas faltantes si las hay"
echo "   4. Verifica permisos del archivo JSON"
echo
