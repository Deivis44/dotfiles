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
        mv "$file" "$file.backup_$(date +%F_%T)"
        show_info "Backup creado: $file.backup_$(date +%F_%T)"
        BACKUP_FILES+=("$file.backup_$(date +%F_%T)")
    fi
}

# Mostrar banner
show_banner

# Inicializar arrays para el resumen
NEW_LINKS=()
BACKUP_FILES=()
SKIPPED_LINKS=()

# Instalación de paquetes necesarios
show_section "Instalando herramientas necesarias"
install_packages() {
    local packages=("stow" "curl" "zathura" "tmux" "neovim" "git" "starship" "python" "python-pynvim" "npm" "zathura-pdf-mupdf")
    for pkg in "${packages[@]}"; do
        if ! pacman -Qs $pkg > /dev/null; then
            show_info "$pkg no está instalado. Instalando $pkg..."
            sudo pacman -Sy --noconfirm $pkg
        else
            show_info "$pkg ya está instalado."
        fi
    done
}
install_packages

# Función para gestionar los dotfiles usando stow
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
add_dotfile "nvim" ".config/nvim"

# Crear backups de archivos o directorios existentes, excepto enlaces simbólicos
show_section "Creando backups si es necesario"
for key in "${!DOTFILES[@]}"; do
    target="${HOME}/${DOTFILES[$key]}"
    backup_file "$target"
done

# Aplicar configuraciones con stow
show_section "Aplicando configuraciones con stow"
for key in "${!DOTFILES[@]}"; do
    target="${HOME}/${DOTFILES[$key]}"
    if [ -L "$target" ]; then
        show_info "Enlace simbólico para $key ya existe en $target. Omitiendo..."
        SKIPPED_LINKS+=("$target")
    else
        show_info "Aplicando configuración para $key..."
        stow -v "$key"
        if [ $? -eq 0 ]; then
            show_info "Configuración para $key aplicada con éxito."
            NEW_LINKS+=("$target")
        else
            show_info "Error al aplicar la configuración para $key."
        fi
    fi
done

# Instalación de NvChad
show_section "Instalando NvChad"
if [ ! -d "$HOME/.config/nvim" ]; then
    show_info "Clonando NvChad en ~/.config/nvim..."
    git clone https://github.com/NvChad/starter ~/.config/nvim
    show_info "NvChad clonado con éxito."
else
    show_info "NvChad ya está instalado en ~/.config/nvim."
fi

# Crear backup del archivo init.lua original
show_section "Creando backup del init.lua original"
if [ -f "$HOME/.config/nvim/init.lua" ]; then
    backup_file "$HOME/.config/nvim/init.lua"
fi

# Sobrescribir init.lua con el archivo personalizado
show_section "Configurando NvChad"
cp ~/dotfiles/nvim/init.lua ~/.config/nvim/init.lua
show_info "Configuración personalizada de NvChad aplicada."

# Configuración personalizada de NvChad
mkdir -p ~/.config/nvim/lua/custom
cp ~/dotfiles/nvim/custom/init.lua ~/.config/nvim/lua/custom/init.lua
cp ~/dotfiles/nvim/custom/plugins.lua ~/.config/nvim/lua/custom/plugins.lua
show_info "Configuración personalizada de NvChad aplicada."

# Instalar Starship sin pedir confirmación
show_section "Instalando Starship"
show_info "Instalando Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- --yes

# Recargar la configuración de tmux
show_section "Recargando configuración de tmux"
show_info "Recargando configuración de tmux..."
tmux new-session -d -s temp_session "tmux source-file ~/.config/tmux/tmux.conf && tmux kill-session -t temp_session"

# Instalar tmux plugin manager (tpm)
show_section "Instalando tmux plugin manager (tpm)"
show_info "Instalando tmux plugin manager (tpm)..."
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

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
show_info "Instalación y configuración completadas."
show_info "Por favor, reinicie la terminal para aplicar los cambios."
show_info "Para tmux, borre todo en la carpeta plugins, a excepcion del directorio 'tpm' y use el comando Ctrl + Space + I para reinstalar los plugins."
