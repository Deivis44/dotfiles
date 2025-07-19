#!/bin/bash

echo "🧪 PRUEBA DIRECTA: Verificar corrección del set -e"
echo "═══════════════════════════════════════════════════════════════════"

cd /home/deivi/dotfiles-dev/Scripts

echo "📋 Probando el instalador corregido directamente..."
echo "   Input: echo \"3\" | timeout 30s ./full_installer_v2.sh"
echo "   (Se cancela automáticamente tras 30 segundos)"
echo

# Ejecutar el instalador real con timeout para evitar que se cuelgue
echo "3" | timeout 30s ./full_installer_v2.sh 2>&1 | tee /tmp/installer_set_e_fix.log &

# Esperar un momento para que procese
sleep 5

# Verificar si sigue ejecutándose
if pgrep -f "full_installer_v2.sh" > /dev/null; then
    echo "✅ El instalador sigue ejecutándose (no se cortó inmediatamente)"
    echo "⏳ Esperando más tiempo para ver el procesamiento..."
    
    # Esperar otros 10 segundos
    sleep 10
    
    if pgrep -f "full_installer_v2.sh" > /dev/null; then
        echo "✅ Aún ejecutándose - esto es buena señal!"
        echo "🛑 Terminando prueba para analizar resultados..."
        pkill -f "full_installer_v2.sh"
        sleep 2
    fi
else
    echo "❌ El instalador se cortó muy rápido"
fi

# Esperar a que termine el tee
wait

echo
echo "📊 ANÁLISIS DEL RESULTADO:"
echo "─────────────────────────────────────────────"

echo
echo "🔍 ¿Aparece el mensaje de verificación de paquetes?"
if grep -q "📊 Verificación: .* paquetes detectados" /tmp/installer_set_e_fix.log; then
    echo "   ✅ SÍ - Llega al procesamiento de paquetes"
    verification_line=$(grep "📊 Verificación: .* paquetes detectados" /tmp/installer_set_e_fix.log | head -1)
    echo "   📋 $verification_line"
else
    echo "   ❌ NO - Se corta antes del procesamiento"
fi

echo
echo "🔍 ¿Aparece el procesamiento de paquetes?"
if grep -q "🔍 Procesando paquete .* de" /tmp/installer_set_e_fix.log; then
    echo "   ✅ SÍ - Inicia el procesamiento de paquetes"
    processing_lines=$(grep -c "🔍 Procesando paquete .* de" /tmp/installer_set_e_fix.log)
    echo "   📊 Número de paquetes procesados: $processing_lines"
else
    echo "   ❌ NO - No llega al procesamiento individual"
fi

echo
echo "🔍 ¿Aparece el resumen de categoría?"
if grep -q "📊 Resumen de .*:" /tmp/installer_set_e_fix.log; then
    echo "   ✅ SÍ - Completa el procesamiento de una categoría"
    resumen_lines=$(grep -c "📊 Resumen de .*:" /tmp/installer_set_e_fix.log)
    echo "   📊 Número de resúmenes de categoría: $resumen_lines"
else
    echo "   ❌ NO - No completa ninguna categoría"
fi

echo
echo "🔍 ¿Aparece el mensaje de continuar?"
if grep -q "🔄 Continuando con la siguiente categoría" /tmp/installer_set_e_fix.log; then
    echo "   ✅ SÍ - Continúa a la siguiente categoría"
    continue_lines=$(grep -c "🔄 Continuando con la siguiente categoría" /tmp/installer_set_e_fix.log)
    echo "   📊 Número de continuaciones: $continue_lines"
else
    echo "   ❌ NO - No continúa a la siguiente categoría"
fi

echo
echo "🔍 ¿Aparece una segunda categoría?"
if grep -q "🎯 Instalando: .* 2\." /tmp/installer_set_e_fix.log; then
    echo "   ✅ SÍ - Procesa la segunda categoría"
    echo "   🎉 ¡EL PROBLEMA DEL SET -E ESTÁ RESUELTO!"
else
    echo "   ❌ NO - Se corta en la primera categoría"
fi

echo
echo "📄 ÚLTIMAS 20 LÍNEAS DE LA SALIDA:"
echo "─────────────────────────────────────────────"
tail -20 /tmp/installer_set_e_fix.log

echo
echo "💡 DIAGNÓSTICO FINAL:"
categories_found=$(grep -c "🎯 Instalando:" /tmp/installer_set_e_fix.log)
echo "   📊 Categorías encontradas en el log: $categories_found"

if [[ $categories_found -gt 1 ]]; then
    echo "   🎉 ¡ÉXITO TOTAL! El instalador procesa múltiples categorías"
    echo "   ✅ El problema del set -e ha sido RESUELTO"
elif [[ $categories_found -eq 1 ]]; then
    processing_count=$(grep -c "🔍 Procesando paquete" /tmp/installer_set_e_fix.log)
    if [[ $processing_count -gt 0 ]]; then
        echo "   🔄 PROGRESO: Al menos procesa una categoría parcialmente"
        echo "   💡 Puede necesitar más tiempo o hay otro problema menor"
    else
        echo "   ⚠️  ESTANCADO: Llega a la categoría pero no procesa paquetes"
    fi
else
    echo "   ❌ FALLO: No llega ni a procesar categorías"
fi

echo
echo "📁 Log completo guardado en: /tmp/installer_set_e_fix.log"
