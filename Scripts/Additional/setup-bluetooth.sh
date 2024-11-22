#!/bin/bash

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor ejecuta este script como root (sudo)." >&2
  exit 1
fi

# Habilitar el servicio de Bluetooth
echo "Habilitando el servicio de Bluetooth..."
systemctl enable bluetooth

# Iniciar el servicio de Bluetooth
echo "Iniciando el servicio de Bluetooth..."
systemctl start bluetooth

# Verificar el estado del servicio
echo "Verificando el estado del servicio de Bluetooth..."
systemctl status bluetooth --no-pager

# Mensaje final
echo "Bluetooth ha sido configurado correctamente."

