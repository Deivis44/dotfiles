#!/bin/bash

show_banner() {
    echo -e "
     _____          ___         ___
    /  /::\        /  /\       /__/\
   /  /:/\:\      /  /::\     |  |::\
  /  /:/  \:\    /  /:/\:\    |  |:|:\
 /__/:/ \__\:|  /  /:/~/:/  __|__|:|\:\
 \  \:\ /  /:/ /__/:/ /:/  /__/::::| \:\
  \  \:\  /:/  \  \:\/:/   \  \:\~~\__\/
   \  \:\/:/    \  \::/     \  \:\
    \  \::/      \  \:\      \  \:\
     \__\/        \  \:\      \  \:\
                   \__\/       \__\/
    "
}

show_banner

# Funciones para mostrar mensajes al usuario
show_info() { echo -e "\e[1;33m$1\e[0m"; }
show_error() { echo -e "\e[1;31m$1\e[0m"; }
show_success() { echo -e "\e[1;32m$1\e[0m"; }

# Función para preguntar al usuario
ask_install() {
    local pkg=$1
    while true; do
        read -p "¿Quieres instalar $pkg? [s/n]: " yn
        case $yn in
            [Ss]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Por favor, responde con s/n.";;
        esac
    done
}

# Función para verificar si un paquete está instalado
is_installed() {
    local pkg=$1
    if pacman -Qi "$pkg" > /dev/null 2>&1 || yay -Qi "$pkg" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Función para instalar yay si no está presente
install_yay() {
    if ! command -v yay > /dev/null; then
        show_info "Instalando yay..."
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm
        if [ $? -eq 0 ]; then
            show_success "yay instalado correctamente."
            rm -rf /tmp/yay
        else
            show_error "Error al instalar yay."
            exit 1
        fi
    else
        show_info "yay ya está instalado."
    fi
}

# Función para instalar un paquete
install_package() {
    local pkg=$1
    local install_all=$2

    if is_installed "$pkg"; then
        show_info "$pkg ya está instalado."
        return 0
    fi

    if [ "$install_all" = true ] || ask_install "$pkg"; then
        show_info "Instalando $pkg..."
        if sudo pacman -S --noconfirm "$pkg"; then
            show_success "$pkg instalado con éxito con pacman."
            return 0
        else
            show_info "No se pudo instalar $pkg con pacman. Intentando con yay..."
            if yay -S --noconfirm "$pkg"; then
                show_success "$pkg instalado con éxito con yay."
                return 0
            else
                show_error "Error al instalar $pkg."
                return 1
            fi
        fi
    else
        show_info "$pkg omitido por el usuario."
        return 2
    fi
}

# Función para instalar grupos de paquetes
install_group() {
    local group_name=$1
    shift
    local packages=("$@")
    local install_all=$install_all

    show_info "-------------------------------------------"
    show_info "Instalando grupo de paquetes: $group_name"
    show_info "-------------------------------------------"
    local total_packages=${#packages[@]}
    for i in "${!packages[@]}"; do
        local pkg=${packages[$i]}
        show_info "[$((i+1))/$total_packages] Instalando: $pkg"
        if install_package "$pkg" "$install_all"; then
            installed+=("$pkg")
        elif [ $? -eq 2 ]; then
            user_skipped+=("$pkg")
        else
            errors+=("$pkg")
        fi
    done
}

# Lista de carpetas específicas que deseas verificar o crear
declare -a required_config_dirs=("kitty" "nvim" "tmux")

# Función para crear carpetas de configuración si no existen
create_required_config_dirs() {
    show_info "Verificando y creando carpetas de configuración especificadas..."
    for config_name in "${required_config_dirs[@]}"; do
        target_dir="$HOME/.config/$config_name"
        if [ ! -d "$target_dir" ]; then
            show_info "Creando directorio de configuración para $config_name en $target_dir"
            mkdir -p "$target_dir"
        else
            show_info "El directorio de configuración $target_dir ya existe. No se necesita crear."
        fi
    done
}

# Función para mostrar el resumen de la instalación
show_summary() {
    show_info "-------------------------------------------"
    show_info "Resumen de la instalación"
    show_info "-------------------------------------------"
    if [ ${#installed[@]} -ne 0 ]; then
        show_info "Paquetes instalados:"
        for item in "${installed[@]}"; do
            show_success " - $item"
        done
    fi
    if [ ${#skipped[@]} -ne 0 ]; then
        show_info "Paquetes ya estaban instalados:"
        for item in "${skipped[@]}"; do
            show_info " - $item"
        done
    fi
    if [ ${#user_skipped[@]} -ne 0 ]; then
        show_info "Paquetes omitidos por el usuario:"
        for item in "${user_skipped[@]}"; do
            show_info " - $item"
        done
    fi
    if [ ${#errors[@]} -ne 0 ]; then
        show_info "Paquetes que fallaron:"
        for item in "${errors[@]}"; do
            show_error " - $item"
        done
    fi
}

# Declaración de arrays para agrupar paquetes por funcionalidad
declare -a installed
declare -a skipped
declare -a user_skipped
declare -a errors

# Gestión de dotfiles y control de versiones
declare -a dotfiles_tools=(
    "stow"
    "git"
)

# Utilidades del sistema
declare -a system_utilities=(
    "linux-headers"
    "curl"
    "unzip"
    "tree"
    "man-db"
    "eza"
    "os-prober"
    "less"
    "fzf"
    "zoxide"
    "ranger"
    "btop"
    "fastfetch"
    "tty-clock"
    "cbonsai"
    "vesktop"
    "cava"
    "bat"
    "pipes.sh"
    "extension-manager"
)

# Aplicaciones de productividad y multimedia
declare -a productivity_apps=(
    "vlc"
    "chromium"
    "obsidian"
    "foliate"
    "veracrypt"
    "keepassxc"
    "spotify-launcher"
    "syncthing"
    "zathura"
    "zathura-pdf-mupdf"
    "telegram-desktop"
    "torbrowser-launcher"
    "openvpn"
    "protonvpn-cli-ng"
    "virtualbox"
    "virtualbox-host-dmks"
    "virtualbox-guest-iso"
    "obs-studio"
    "minecraft-launcher"
    "thunderbird"
    "onlyoffice-bin"
    "zen-browser-bin"
    "librewolf-bin"
    "mullvad-browser-bin"
)

# Herramientas de desarrollo y programación
declare -a development_tools=(
    "neovim"
    "python"
    "python-pynvim"
    "npm"
    "python-virtualenv"
    "pyright"
    "go"
    "base-devel"
    "gcc"
    "lazygit"
    "zig"
    "jdk21-openjdk"
)

# Terminal y shell
declare -a terminal_shell=(
    "kitty"
    "zsh"
    "pokemon-colorscripts-git"
)

# Fuentes y símbolos
declare -a fonts_symbols=(
    "noto-fonts"
    "noto-fonts-extra"
    "noto-fonts-emoji"
    "noto-fonts-cjk"
    "ttf-nerd-fonts-symbols"
    "ttf-nerd-fonts-symbols-mono"
)

# Herramientas y plugins para Tmux
declare -a tmux_plugins=(
    "tmux"
    "bc"
    "jq"
    "glab"
    "playerctl"
)

# Instalación de los paquetes en cada grupo
install_packages() {
    local install_all=$1

    install_yay
    install_group "Gestión de Dotfiles y Control de Versiones" "${dotfiles_tools[@]}"
    install_group "Utilidades del Sistema" "${system_utilities[@]}"
    install_group "Aplicaciones de Productividad y Multimedia" "${productivity_apps[@]}"
    install_group "Herramientas de Desarrollo y Programación" "${development_tools[@]}"
    install_group "Terminal y Shell" "${terminal_shell[@]}"
    install_group "Fuentes y Símbolos" "${fonts_symbols[@]}"
    install_group "Herramientas y Plugins para Tmux" "${tmux_plugins[@]}"

    create_required_config_dirs
    show_summary
}

# Preguntar si se desea instalar todo de una vez o uno por uno
read -p "¿Quieres instalar todos los paquetes de corrido? [s/n]: " install_all
if [[ $install_all =~ ^[Ss]$ ]]; then
    install_packages true
else
    install_packages false
fi

