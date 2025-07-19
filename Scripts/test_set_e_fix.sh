#!/bin/bash

echo "🧪 PRUEBA DE CORRECCIÓN: Problema del set -e resuelto"
echo "═══════════════════════════════════════════════════════════════════"

cd /home/deivi/dotfiles-dev/Scripts

echo "📋 Probando el instalador corregido (sin sudo)..."
echo "   Este test debería procesar múltiples categorías sin cortarse"
echo

# Crear un script de prueba que solo procese la lógica de paquetes
cat > /tmp/test_set_e_fix.sh << 'EOF'
#!/bin/bash

# Importar las funciones del instalador
source /home/deivi/dotfiles-dev/Scripts/full_installer_v2.sh

# Variables necesarias
PACKAGES_JSON="/home/deivi/dotfiles-dev/Scripts/packages.json"
TOTAL_INSTALLED=0
TOTAL_SKIPPED=0
TOTAL_FAILED=0

# Versión de install_package que simula sin sudo para testing
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
    
    # En modo selectivo no-interactivo, simular respuesta automática
    if [[ "$install_mode" == "selective" ]]; then
        if [[ ! -t 0 ]]; then
            # Simular decisión automática: instalar paquetes que empiecen con a-m, omitir n-z
            if [[ "${package:0:1}" < "n" ]]; then
                info "   🔄 [TEST] Simulando instalación automática de $package"
            else
                info "   ⏭️  [TEST] Simulando omisión automática de $package"
                ((TOTAL_SKIPPED++))
                return 2
            fi
        fi
    fi
    
    info "   🔄 [TEST] Simulando instalación de $package..."
    
    # Simular instalación exitosa
    success "   ✅ [TEST] $package instalado correctamente (simulado)"
    ((TOTAL_INSTALLED++))
    return 0
}

# Función de prueba que procesa solo las primeras 3 categorías
test_categories() {
    local categories=()
    
    info "🔍 Leyendo categorías del JSON..."
    while IFS= read -r category_id; do
        if [[ -n "$category_id" ]] && [[ "$category_id" != "null" ]]; then
            categories+=("$category_id")
            info "  ✓ Encontrada categoría: $category_id"
        fi
    done < <(jq -r '.categories[].id' "$PACKAGES_JSON" 2>/dev/null)
    
    info "📋 Procesando primeras 3 categorías para verificar flujo..."
    echo
    
    local count=0
    for category in "${categories[@]}"; do
        if [[ $count -ge 3 ]]; then
            info "🛑 Limitando prueba a 3 categorías"
            break
        fi
        
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        info "🧪 PRUEBA $((count + 1)): Procesando categoría: $category"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        install_category "$category" "selective"
        
        echo
        info "✅ Categoría $category completada - continuando..."
        echo
        
        ((count++))
    done
    
    echo
    success "🎉 ¡PRUEBA COMPLETADA! Procesadas $count categorías sin interrupciones"
    info "📊 Estadísticas de prueba:"
    info "   ✅ Instalados: $TOTAL_INSTALLED"
    info "   ⏭️  Omitidos: $TOTAL_SKIPPED"
    info "   ❌ Fallidos: $TOTAL_FAILED"
}

# Ejecutar prueba
test_categories
EOF

chmod +x /tmp/test_set_e_fix.sh

echo "🚀 Ejecutando prueba (modo no-interactivo)..."
echo "═══════════════════════════════════════════════════════════════════"

# Ejecutar la prueba
echo "test" | /tmp/test_set_e_fix.sh 2>&1 | tee /tmp/set_e_test_result.log

exit_code=${PIPESTATUS[1]}

echo
echo "📊 ANÁLISIS DEL RESULTADO:"
echo "─────────────────────────────────────────────"
echo "🔍 Código de salida: $exit_code"

echo
echo "🧪 VERIFICACIONES:"
echo "─────────────────────────────────────────────"

categories_processed=$(grep -c "🧪 PRUEBA" /tmp/set_e_test_result.log)
echo "📊 Categorías procesadas: $categories_processed"

if grep -q "🎉 ¡PRUEBA COMPLETADA!" /tmp/set_e_test_result.log; then
    echo "✅ El script llegó hasta el final sin cortarse"
else
    echo "❌ El script se cortó antes de completar"
fi

if grep -q "Continuando con la siguiente categoría" /tmp/set_e_test_result.log; then
    echo "✅ El flujo entre categorías funciona"
else
    echo "❌ El flujo entre categorías no funciona"
fi

echo
echo "📄 ÚLTIMAS 10 LÍNEAS DE LA SALIDA:"
echo "─────────────────────────────────────────────"
tail -10 /tmp/set_e_test_result.log

echo
echo "💡 CONCLUSIÓN:"
if [[ $categories_processed -ge 3 ]] && grep -q "🎉 ¡PRUEBA COMPLETADA!" /tmp/set_e_test_result.log; then
    echo "   🎉 ¡ÉXITO! El problema del set -e ha sido RESUELTO"
    echo "   ✅ El instalador ahora procesa múltiples categorías correctamente"
    echo "   🚀 El script está listo para uso real"
else
    echo "   ⚠️  Aún hay problemas - revisar la salida de la prueba"
fi

echo
echo "📁 Log completo guardado en: /tmp/set_e_test_result.log"
