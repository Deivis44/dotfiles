#!/bin/bash

echo "🎯 PRUEBA EXACTA: Reproducir el comportamiento que describes"
echo "═══════════════════════════════════════════════════════════════════"

# Simular exactamente lo que hace el instalador real
cd /home/deivi/dotfiles-dev/Scripts

echo "📋 Ejecutando el instalador real en modo selectivo con pipe..."
echo "   Input: echo '3' | ./full_installer_v2.sh"
echo

# Capturar la salida del instalador real
echo "3" | timeout 30s ./full_installer_v2.sh 2>&1 | tee /tmp/installer_output.log

exit_code=${PIPESTATUS[1]}

echo
echo "📊 ANÁLISIS DEL RESULTADO:"
echo "──────────────────────────────────────"
echo "🔍 Código de salida: $exit_code"
echo "📄 Últimas 20 líneas de la salida:"
echo "──────────────────────────────────────"
tail -20 /tmp/installer_output.log

echo
echo "📋 LÍNEAS CLAVE ENCONTRADAS:"
echo "──────────────────────────────────────"
echo "🔍 Líneas con 'Verificación':"
grep -n "Verificación" /tmp/installer_output.log || echo "   ❌ No encontrado"

echo "🔍 Líneas con 'paquetes detectados':"
grep -n "paquetes detectados" /tmp/installer_output.log || echo "   ❌ No encontrado"

echo "🔍 Líneas con 'Procesando paquete':"
grep -n "Procesando paquete" /tmp/installer_output.log || echo "   ❌ No encontrado"

echo "🔍 Última línea del archivo:"
tail -1 /tmp/installer_output.log

echo
echo "💡 DIAGNÓSTICO:"
if grep -q "Verificación: 2 paquetes detectados" /tmp/installer_output.log; then
    echo "   ✅ El mensaje de verificación aparece"
    if grep -q "Procesando paquete 1 de" /tmp/installer_output.log; then
        echo "   ✅ El procesamiento de paquetes inicia"
        echo "   🤔 El script debería continuar... revisando por qué se corta"
    else
        echo "   ❌ El procesamiento de paquetes NO inicia"
        echo "   🔍 El problema está en el loop while del install_category"
    fi
else
    echo "   ❌ El mensaje de verificación no aparece"
    echo "   🔍 El problema está antes del procesamiento"
fi

echo
echo "📁 Archivo completo de salida guardado en: /tmp/installer_output.log"
