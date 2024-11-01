#!/bin/bash

# Función para mostrar un banner
show_banner() {
    echo -e "\e[1;34m"
    echo "                    ___           ___     "
    echo "     _____         /\  \         /\__\    "
    echo "    /::\  \       /::\  \       /:/ _/_   "
    echo "   /:/\:\  \     /::::\  \     /:/ /\__\  "
    echo "  /:/  \:\__\   /::::::\  \   /:/ /:/  /  "
    echo " /:/__/ \:|__| /:::DM:::\__\ /:/_/:/  /   "
    echo " \:\  \ /:/  / \::2004::/  / \:\/:/  /    "
    echo "  \:\  /:/  /   \::::::/  /   \::/__/     "
    echo "   \:\/:/  /     \::::/  /     \:\  \     "
    echo "    \::/  /       \::/  /       \:\__\    "
    echo "     \/__/         \/__/         \/__/    "
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
backup_file() {
    local file=$1
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        show_info "El archivo o directorio $file ya existe y no es un enlace simbólico. Creando backup..."
        local backup_name="$file.backup_$(date +%F_%T)"
        mv "$file" "$backup_name"
        show_info "Backup creado: $backup_name"
        BACKUP_FILES+=("$backup_name")
    fi
}

# Mostrar banner
show_banner

# Inicializar arrays para el resumen
declare -a NEW_LINKS
declare -a BACKUP_FILES
declare -a SKIPPED_LINKS

# Declarar array asociativo para dotfiles
declare -A DOTFILES

# Añadir configuraciones existentes en la nueva estructura
add_dotfile() {
    local name=$1
    local path=$2
    DOTFILES["$name"]="$path"
}

# Añadir dotfiles según la nueva estructura en Config/
add_dotfile "zsh" "Config/zsh/.zshrc"
add_dotfile "ranger" "Config/ranger/.config/ranger/rc.conf"
add_dotfile "tmux" "Config/tmux/.config/tmux/tmux.conf"
add_dotfile "starship" "Config/starship/.config/starship.toml"
add_dotfile "zathura" "Config/zathura/.config/zathura/zathurarc"
add_dotfile "nvim_custom" "Config/nvim/.config/nvim/lua/custom"
add_dotfile "nvim_init" "Config/nvim/.config/nvim/init.lua"
add_dotfile "git" "Config/git/.gitconfig"
add_dotfile "kitty" "Config/kitty/.config/kitty/kitty.conf"

# Crear backups de archivos o directorios existentes, excepto enlaces simbólicos
show_section "Creando backups si es necesario"
for key in "${!DOTFILES[@]}"; do
    target="${HOME}/${DOTFILES[$key]}"
    backup_file "$target"
done

# Aplicar configuraciones con enlaces simbólicos específicos
show_section "Aplicando configuraciones con enlaces simbólicos"
for key in "${!DOTFILES[@]}"; do
    source_path="${HOME}/dotfiles/${DOTFILES[$key]}"
    target_path="${HOME}/${DOTFILES[$key]}"
    
    # Si el archivo ya existe, eliminarlo para crear un nuevo enlace simbólico
    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        rm -rf "$target_path"
    fi
    
    # Crear el enlace simbólico
    ln -s "$source_path" "$target_path"
    show_info "Enlace simbólico creado desde $source_path hacia $target_path"
    NEW_LINKS+=("$target_path")
done

# Resumen
show_section "Resumen de la instalación"
echo "Enlaces nuevos creados y ubicaciones:"
for link in "${NEW_LINKS[@]}"; do
    echo " - $link"
done

echo "---------------------------"
echo "Archivos o carpetas ya existentes que fueron respaldados:"
for backup in "${BACKUP_FILES[@]}"; do
    echo " - $backup"
done

# Mensajes de información adicionales
show_section "Información adicional"
show_info "Instalación y configuración completadas. Recuerda:"
show_info "- Abre tmux y usa Ctrl + Space + Shift + I para instalar los plugins descritos en el archivo tmux.conf."
show_info "- Abre Neovim para verificar que las configuraciones personalizadas y plugins se han cargado correctamente. Ademas usar ':MasonInstallAll'"
show_info "- Reinicia la terminal para aplicar los cambios en Starship."

echo "---------------------------"
show_info "Para problemas o preguntas, consulta el README del repositorio. ¡Buena suerte!"
