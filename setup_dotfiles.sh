#!/bin/bash

# Función para hacer backup de archivos o enlaces simbólicos existentes
backup_file() {
    local file=$1
    if [ -e "$file" ]; then
        echo "El archivo o enlace $file ya existe. Creando backup..."
        mv "$file" "$file.backup_$(date +%F_%T)"
        echo "Backup creado: $file.backup_$(date +%F_%T)"
    fi
}

# Instalación de stow si no está instalado
if ! command -v stow &> /dev/null; then
    echo "stow no está instalado. Instalando stow..."
    sudo pacman -Sy stow --noconfirm
else
    echo "stow ya está instalado."
fi

# Directorio de dotfiles
DOTFILES_DIR=$(pwd)

# Archivos y carpetas a configurar
declare -A DOTFILES

# Función para añadir un archivo de configuración
add_dotfile() {
    local name=$1
    local path=$2
    DOTFILES["$name"]="$path"
}

# Añadir configuraciones existentes
add_dotfile "zsh" ".zshrc"
add_dotfile "ranger" ".config/ranger"
add_dotfile "tmux" ".config/tmux"
add_dotfile "starship" ".config/starship.toml"
add_dotfile "zathura" ".config/zathura"
# ------ USAR LA FUNCIÓN PARA AÑADIR NUEVOS ARCHIVOS ------

# Crear backups y aplicar configuraciones con stow
for key in "${!DOTFILES[@]}"; do
    target="${HOME}/${DOTFILES[$key]}"
    backup_file "$target"
done

# Aplicar configuraciones con stow
for key in "${!DOTFILES[@]}"; do
    echo "Aplicando configuración para $key..."
    stow -v "$key"
    if [ $? -eq 0 ]; then
        echo "Configuración para $key aplicada con éxito."
    else
        echo "Error al aplicar la configuración para $key."
    fi
done

echo "Proceso de configuración completado."
