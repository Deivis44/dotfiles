#!/bin/bash

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

# Función para hacer backup de archivos o directorios existentes, excepto enlaces simbólicos
backup_file_unlink() {
    local file=$1
    if [ -L "$file" ]; then
        show_info "El enlace simbólico $file será eliminado. Creando backup del destino..."
        local target=$(readlink "$file")
        mv "$target" "$target.unlink_$(date +%F_%T)"
        rm "$file"
        show_info "Backup creado: $target.unlink_$(date +%F_%T)"
        show_info "Enlace simbólico eliminado: $file"
    fi
}

# Mostrar banner
show_banner

# Inicializar arrays para el resumen
REMOVED_LINKS=()
UNLINKED_FILES=()

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
add_dotfile "tmux" ".config/tmux/tmux.conf"  # Sólo eliminar el enlace de tmux.conf
add_dotfile "starship" ".config/starship.toml"
add_dotfile "zathura" ".config/zathura"
add_dotfile "nvim" ".config/nvim"

# Eliminar enlaces simbólicos y crear backups de los destinos
show_section "Eliminando enlaces simbólicos y creando backups si es necesario"
for key in "${!DOTFILES[@]}"; do
    target="${HOME}/${DOTFILES[$

