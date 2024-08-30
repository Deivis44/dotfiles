#!/bin/bash

# Función para mostrar un banner bonito
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

# Añadir configuraciones existentes
add_dotfile() {
    local name=$1
    local path=$2
    DOTFILES["$name"]="$path"
}

# Añadir dotfiles
add_dotfile "zsh" ".zshrc"
add_dotfile "ranger" ".config/ranger"
add_dotfile "tmux" ".config/tmux/tmux.conf"  # Sólo crear enlace para tmux.conf
add_dotfile "starship" ".config/starship.toml"
add_dotfile "zathura" ".config/zathura"
add_dotfile "nvim_custom" ".config/nvim/lua/custom"  # Crear enlace para la carpeta custom en NvChad
add_dotfile "nvim_init" ".config/nvim/init.lua"  # Crear enlace para init.lua de NvChad
add_dotfile "git" ".gitconfig"

# Crear backups de archivos o directorios existentes, excepto enlaces simbólicos
show_section "Creando backups si es necesario"
for key in "${!DOTFILES[@]}"; do
    target="${HOME}/${DOTFILES[$key]}"
    if [ "$key" == "nvim_init" ]; then
        if [ -f "$target" ] && [ ! -L "$target" ]; then
            backup_file "$target"
        fi
    else
        backup_file "$target"
    fi
done

# Aplicar configuraciones con stow y enlaces simbólicos específicos
show_section "Aplicando configuraciones con stow"
for key in "${!DOTFILES[@]}"; do
    if [ "$key" == "nvim_custom" ]; then
        # Enlazar la carpeta custom
        show_info "Enlazando la carpeta 'custom' en NvChad"
        CUSTOM_SOURCE="$HOME/dotfiles/nvim/.config/nvim/lua/custom"
        CUSTOM_TARGET="$HOME/.config/nvim/lua/custom"
        
        if [ -L "$CUSTOM_TARGET" ] || [ -d "$CUSTOM_TARGET" ]; then
            show_info "El enlace simbólico o carpeta 'custom' ya existe en $CUSTOM_TARGET. Eliminando..."
            rm -rf "$CUSTOM_TARGET"
        fi
        
        ln -s "$CUSTOM_SOURCE" "$CUSTOM_TARGET"
        show_info "Enlace simbólico creado desde $CUSTOM_SOURCE hacia $CUSTOM_TARGET"
        NEW_LINKS+=("$CUSTOM_TARGET")
        
    elif [ "$key" == "nvim_init" ]; then
        # Reemplazar init.lua
        show_info "Reemplazando el archivo 'init.lua' en NvChad"
        INIT_SOURCE="$HOME/dotfiles/nvim/.config/nvim/init.lua"
        INIT_TARGET="$HOME/.config/nvim/init.lua"
        
        if [ -f "$INIT_TARGET" ] && [ ! -L "$INIT_TARGET" ]; then
            show_info "El archivo 'init.lua' ya existe en $INIT_TARGET. Creando backup..."
            backup_file "$INIT_TARGET"
        fi
        
        ln -sf "$INIT_SOURCE" "$INIT_TARGET"
        show_info "Enlace simbólico creado desde $INIT_SOURCE hacia $INIT_TARGET"
        NEW_LINKS+=("$INIT_TARGET")
        
    else
        show_info "Aplicando configuración para $key..."
        stow -v --target="$HOME" "$key"
        if [ $? -eq 0 ]; then
            NEW_LINKS+=("${DOTFILES[$key]}")
            show_info "Configuración para $key aplicada con éxito."
        else
            show_info "Error al aplicar la configuración para $key."
        fi
    fi
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

echo "---------------------------"
echo "Enlaces ya existentes que fueron omitidos:"
for skipped in "${SKIPPED_LINKS[@]}"; do
    echo " - $skipped"
done

# Mensajes de información adicionales
show_section "Información adicional"
show_info "Instalación y configuración completadas. Recuerda:"
show_info "- Después de aplicar los enlaces, abre tmux y usa Ctrl + Space + Shift + I para instalar los plugins descritos en el archivo tmux.conf."
show_info "- Abre Neovim para verificar que las configuraciones personalizadas y plugins se han cargado correctamente."
show_info "- Reinicia la terminal para aplicar los cambios en Starship."

