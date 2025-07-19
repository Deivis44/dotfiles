#!/bin/bash

# TEST PARA MODO SELECTIVO - Verificación del comportamiento interactivo

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"

# Funciones de logging
info() { echo -e "\033[34m[INFO]\033[0m $*"; }
success() { echo -e "\033[32m[SUCCESS]\033[0m $*"; }
warning() { echo -e "\033[33m[WARNING]\033[0m $*"; }
error() { echo -e "\033[31m[ERROR]\033[0m $*"; }

echo "🧪 PRUEBA DEL MODO SELECTIVO"
echo "═══════════════════════════════════════════════════════════════"
echo

# Verificar que el JSON existe
if [[ ! -f "$PACKAGES_JSON" ]]; then
    error "❌ Archivo packages.json no encontrado en: $PACKAGES_JSON"
    exit 1
fi

info "📄 Usando JSON: $PACKAGES_JSON"
echo

## Simular el procesamiento de todas las categorías
while IFS= read -r category_info; do
    emoji=$(echo "$category_info" | jq -r '.emoji // "📦"')
    desc=$(echo "$category_info" | jq -r '.description // "Sin descripción"')
    packages_count=$(echo "$category_info" | jq '.packages | length')
    category_id=$(echo "$category_info" | jq -r '.id')

    echo
    info "🎯 Procesando categoría: $emoji $category_id"
    echo "   📋 $desc"
    echo "   📊 $packages_count paquetes en esta categoría"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    current=0
    while IFS= read -r package_info; do
        if [[ -n "$package_info" ]] && [[ "$package_info" != "null" ]]; then
            ((current++))
            name=$(echo "$package_info" | jq -r '.name // ""')
            repo=$(echo "$package_info" | jq -r '.repo // "pacman"')
            optional=$(echo "$package_info" | jq -r '.optional // false')
            desc_pkg=$(echo "$package_info" | jq -r '.description // ""')

            if [[ -z "$name" ]]; then
                warning "Paquete sin nombre encontrado, omitiendo..."
                continue
            fi

            echo
            printf "📦 [%d/%d] %s" "$current" "$packages_count" "$name"
            if [[ -n "$desc_pkg" ]]; then
                printf " - %s" "$desc_pkg"
            fi
            echo

            # Simular verificación de instalación
            if pacman -Qi "$name" >/dev/null 2>&1; then
                success "   ✅ $name ya está instalado"
            else
                info "   ❓ $name no está instalado (repo hint: $repo)"
                echo "   🤔 En modo selectivo, aquí se preguntaría: '¿Quieres instalar $name? [s/n]:'"
            fi
        fi
    done < <(echo "$category_info" | jq -c '.packages[]?')

    # Resumen de la categoría
    echo
    echo "───────────────────────────────────────────────────────────────"
    info "📊 Resumen de $category_id: paquetes explorados: $packages_count"
    echo "───────────────────────────────────────────────────────────────"
done < <(jq -c '.categories[]' "$PACKAGES_JSON")

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "✅ Test del modo selectivo completado"
echo
info "💡 El instalador real haría esto para TODAS las categorías seleccionadas"
info "🔧 Para probarlo realmente, usa: ./full_installer_v2.sh y selecciona opción 3"
echo
