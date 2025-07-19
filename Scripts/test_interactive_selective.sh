#!/bin/bash

# Interacción automatizada para probar el modo selectivo
# Opción 3 + confirmación "y" + algunas respuestas para paquetes

cd /home/deivi/dotfiles-dev/Scripts

# Preparar las respuestas:
# - "3" para seleccionar modo selectivo
# - "y" para confirmar continuar
# - "n" para omitir la primera categoría completa (stow y git)
# - Ctrl+C para salir después de la demostración

echo "🧪 INICIANDO PRUEBA DEL MODO SELECTIVO..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Configuración de la prueba:"
echo "   • Modo: 3 (selectivo)"  
echo "   • Confirmación: y (sí, continuar)"
echo "   • Para paquetes: responderás manualmente"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "🎯 INSTRUCCIONES:"
echo "   1. El instalador iniciará en modo selectivo"
echo "   2. Para cada paquete preguntará: ¿Quieres instalar [paquete]? [s/n]"
echo "   3. Responde 's' para instalar, 'n' para omitir" 
echo "   4. Presiona Ctrl+C cuando quieras terminar la prueba"
echo
read -p "📋 ¿Estás listo para iniciar la prueba? [Enter para continuar] "

echo
echo "🚀 Ejecutando: ./full_installer_v2.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Ejecutar el instalador con la entrada inicial
{
    echo "3"    # Seleccionar modo selectivo
    echo "y"    # Confirmar continuar con selección individual
    sleep 1
    # Después de esto, el usuario tendrá que responder manualmente a cada paquete
} | ./full_installer_v2.sh
