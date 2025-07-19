#!/bin/bash

echo "🧪 PRUEBA RÁPIDA: Verificar el problema del loop"
echo "════════════════════════════════════════════════════════════════"

cd /home/deivi/dotfiles-dev/Scripts

echo "📋 Ejecutando solo la primera categoría con debug mejorado..."
echo "   Esto debería mostrar el procesamiento completo"
echo

# Ejecutar el instalador en modo selectivo
./full_installer_v2.sh << 'EOF'
3
EOF
