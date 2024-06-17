#!/bin/bash

# Directorio del repositorio de dotfiles
DOTFILES_DIR="$HOME/dotfiles"

# Función para verificar e instalar stow
install_stow() {
  if ! command -v stow &> /dev/null; then
    echo "Stow no está instalado. Instalando stow..."
    sudo pacman -S --noconfirm stow
  else
    echo "Stow ya está instalado. Omitiendo instalación."
  fi
}

# Instalar stow si es necesario
install_stow

# Crear enlaces simbólicos usando stow
cd "$DOTFILES_DIR" || exit

echo "Creando enlaces simbólicos..."

# Iterar sobre cada subdirectorio en dotfiles
for dir in * ; do
  if [ -d "$dir" ]; then
    echo "Procesando directorio: $dir"

    # Desinstalar cualquier enlace simbólico existente para el directorio
    stow -D "$dir" -t "$HOME"

    # Crear el enlace simbólico
    stow "$dir" -t "$HOME"
    
    echo "Enlace simbólico creado para: $dir"
  fi
done

echo "Todos los enlaces simbólicos han sido creados con stow."
