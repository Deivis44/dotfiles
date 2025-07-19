#!/bin/bash

echo "🧪 PRUEBA DE CORRECCIÓN: Instalador con pipe en modo selectivo"
echo "═══════════════════════════════════════════════════════════════════"

cd /home/deivi/dotfiles-dev/Scripts

echo "📋 Probando el instalador corregido..."
echo "   Input: echo '3' | timeout 60s ./full_installer_v2.sh"
echo

# Probar el instalador corregido con timeout
echo "3" | timeout 60s ./full_installer_v2.sh 2>&1 | tee /tmp/installer_corrected.log

exit_code=${PIPESTATUS[1]}

echo
echo "📊 ANÁLISIS DEL RESULTADO CORREGIDO:"
echo "─────────────────────────────────────────────"
echo "🔍 Código de salida: $exit_code"

echo
echo "📋 VERIFICACIONES IMPORTANTES:"
echo "─────────────────────────────────────────────"

echo "🔍 ¿Aparece 'Verificación: 2 paquetes detectados'?"
if grep -q "Verificación: 2 paquetes detectados" /tmp/installer_corrected.log; then
    echo "   ✅ SÍ - El mensaje aparece"
else
    echo "   ❌ NO - El mensaje no aparece"
fi

echo "🔍 ¿Aparece 'Procesando paquete 1 de'?"
if grep -q "Procesando paquete 1 de" /tmp/installer_corrected.log; then
    echo "   ✅ SÍ - El procesamiento inicia"
else
    echo "   ❌ NO - El procesamiento no inicia"
fi

echo "🔍 ¿Aparece 'Continuando con la siguiente categoría'?"
if grep -q "Continuando con la siguiente categoría" /tmp/installer_corrected.log; then
    echo "   ✅ SÍ - Continúa a la siguiente categoría"
else
    echo "   ❌ NO - Se corta antes de continuar"
fi

echo "🔍 ¿Aparece 'CORE_SYSTEM'?"
if grep -q "CORE_SYSTEM" /tmp/installer_corrected.log; then
    echo "   ✅ SÍ - Procesa la segunda categoría"
else
    echo "   ❌ NO - Se corta en la primera categoría"
fi

echo "🔍 ¿Aparece algún error relacionado con stdin?"
if grep -qi "stdin\|input\|read.*error" /tmp/installer_corrected.log; then
    echo "   ⚠️  SÍ - Hay problemas de entrada"
    grep -i "stdin\|input\|read.*error" /tmp/installer_corrected.log
else
    echo "   ✅ NO - Sin problemas de entrada detectados"
fi

echo
echo "📄 ÚLTIMAS 15 LÍNEAS DE LA SALIDA:"
echo "─────────────────────────────────────────────"
tail -15 /tmp/installer_corrected.log

echo
echo "💡 DIAGNÓSTICO FINAL:"
categories_found=$(grep -c "🎯 Instalando:" /tmp/installer_corrected.log)
echo "   📊 Categorías procesadas: $categories_found"

if [[ $categories_found -gt 1 ]]; then
    echo "   🎉 ¡ÉXITO! El instalador continúa a través de múltiples categorías"
elif [[ $categories_found -eq 1 ]]; then
    echo "   ⚠️  PARCIAL: Solo procesó una categoría, verificar por qué se corta"
else
    echo "   ❌ FALLO: No procesó ninguna categoría correctamente"
fi

echo
echo "📁 Log completo guardado en: /tmp/installer_corrected.log"
