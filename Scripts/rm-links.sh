#!/bin/bash

# Ruta base para los dotfiles en Config dentro del repositorio de dotfiles
DOTFILES_DIR="$HOME/dotfiles/Config"

# Función para mostrar un banner bonito
show_banner() {
    echo -e "\e[1;34m"
    echo "                    ___           ___     "
    echo "      ___          /  /\         /  /\    "
    echo "     /  /\        /  /::\       /  /::\   "
    echo "    /  /::\      /  /::::\     /  /:/\:\  "
    echo "   /  /:/\:\    /  /::::::\   /  /:/  \:\ "
    echo "  /  /::\ \:\  /__/:::DM:::\ /__/:/ \__\:|"
    echo " /__/:/\:\ \:\ \  \::2004::/ \  \:\ /  /:/"
    echo " \__\/  \:\_\/  \  \::::::/   \  \:\  /:/ "
    echo "      \  \:\     \  \::::/     \  \:\/:/  "
    echo "       \__\/      \  \::/       \__\::/   "
    echo "                   \__\/            ~~    "
    echo -e "\e[0m"
}

# Función para mostrar un título de sección
show_section() {
    local section=$1
    echo -e "\e[1;32m"
    echo "-------------------------------------------"
    echo " $section"
    echo "-------------------------------------------"
    echo -e "\e[0m"
}

# Función para mostrar un mensaje de información
show_info() {
    local message=$1
    echo -e "\e[1;33m$message\e[0m"
}

# Función para hacer backup y eliminar enlace simbólico si existe
backup_file_unlink() {
    local file=$1
    if [ -L "$file" ]; then
        show_info "El enlace simbólico $file será eliminado. Creando backup del destino..."
        local target=$(readlink "$file")
        local backup_name="$target.unlink_$(date +%F_%T)"
        mv "$target" "$backup_name"
        rm "$file"
        show_info "Backup creado: $backup_name"
        show_info "Enlace simbólico eliminado: $file"
        UNLINKED_FILES+=("$backup_name")
        REMOVED_LINKS+=("$file")
    else
        show_info "No se encontró un enlace simbólico en $file."
    fi
}

# Mostrar banner
show_banner

# Inicializar arrays para el resumen
declare -a REMOVED_LINKS
declare -a UNLINKED_FILES

# Declarar array asociativo para dotfiles
declare -A DOTFILES

# Añadir configuraciones de dotfiles
add_dotfile() {
    local name=$1
    local path=$2
    DOTFILES["$name"]="$path"
}

# Añadir dotfiles
add_dotfile "zsh" ".zshrc"
add_dotfile "ranger" ".config/ranger"
add_dotfile "tmux" ".config/tmux/tmux.conf"
add_dotfile "starship" ".config/starship.toml"
add_dotfile "zathura" ".config/zathura"
add_dotfile "nvim_custom" ".config/nvim/lua/custom"
add_dotfile "nvim_init" ".config/nvim/init.lua"
add_dotfile "git" ".gitconfig"
add_dotfile "kitty" ".config/kitty/kitty.conf"  # Configuración específica para kitty.conf

# Eliminar enlaces simbólicos y crear backups de los destinos
show_section "Eliminando enlaces simbólicos y creando backups si es necesario"
for key in "${!DOTFILES[@]}"; do
    target="${HOME}/${DOTFILES[$key]}"
    backup_file_unlink "$target"
done

# Resumen de la operación
show_section "Resumen de la eliminación de enlaces simbólicos"
echo "Enlaces simbólicos eliminados:"
for link in "${REMOVED_LINKS[@]}"; do
    echo " - $link"
done

echo "---------------------------"
echo "Archivos respaldados de los destinos de enlaces eliminados:"
for backup in "${UNLINKED_FILES[@]}"; do
    echo " - $backup"
done

# Mensaje final
show_section "Proceso completado"
show_info "La eliminación de enlaces simbólicos ha sido completada con éxito. Los enlaces y sus destinos han sido respaldados."

