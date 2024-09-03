#!/bin/bash

# Función para mostrar un mensaje de información
show_info() {
    local message=$1
    echo -e "\e[1;33m$message\e[0m"
}

# Función para mostrar un mensaje de error
show_error() {
    local message=$1
    echo -e "\e[1;31m$message\e[0m"
}

# Función para mostrar un mensaje de éxito
show_success() {
    local message=$1
    echo -e "\e[1;32m$message\e[0m"
}

# Función para preguntar si se desea instalar un paquete
ask_install() {
    local pkg=$1
    while true; do
        read -p "¿Quieres instalar $pkg? [s/n]: " yn
        case $yn in
            [Ss]* ) return 0;;  # Sí
            [Nn]* ) return 1;;  # No
            * ) echo "Por favor, responde con s/n.";;
        esac
    done
}

# Función para instalar un paquete usando pacman o yay
install_package() {
    local pkg=$1
    local install_all=$2

    if pacman -Qs $pkg > /dev/null; then
        show_info "$pkg ya está instalado."
        return 0
    fi

    if [ "$install_all" = true ] || ask_install "$pkg"; then
        show_info "Intentando instalar $pkg con pacman..."
        if sudo pacman -Syu --noconfirm $pkg; then
            show_success "$pkg instalado con éxito con pacman."
            return 0
        else
            show_info "No se pudo instalar $pkg con pacman. Intentando con yay..."
            if yay -Syu --noconfirm $pkg; then
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

# Función para verificar si la fuente CaskaydiaCove Nerd Font Mono ya está instalada
check_and_install_font() {
    local font_name="CaskaydiaCove Nerd Font Mono"
    
    if fc-list | grep -qi "$font_name"; then
        show_info "La fuente $font_name ya está instalada."
        return 0
    fi
    
    show_info "La fuente $font_name no está instalada. Intentando instalarla..."
    
    # Descargar la fuente
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/CascadiaCode.zip -O /tmp/CascadiaCode.zip
    if [ $? -ne 0 ]; then
        show_error "Error al descargar $font_name."
        return 1
    fi
    
    # Descomprimir y mover la fuente
    unzip /tmp/CascadiaCode.zip -d ~/.local/share/fonts
    if [ $? -ne 0 ]; then
        show_error "Error al descomprimir $font_name."
        return 1
    fi
    
    # Actualizar la caché de fuentes
    fc-cache -fv
    show_success "La fuente $font_name se instaló correctamente."
}

# Listas de paquetes, agrupadas por categoría para facilitar su mantenimiento
declare -a dotfiles_tools=(
    "stow"
    "git"
)

declare -a system_utilities=(
    "curl"
    "unzip"
    "tree"
    "eza"
    "os-prober"
    "less"
    "fzf"
    "zoxide"
    "ranger"
    "btop"
    "neofetch"
    "vesktop"
    "chromium"
    "obsidian"
    "foliate"
    "veracrypt"
    "keepassxc"
    "spotify-launcher"
    "syncthing"
    "starship"
    "zathura"
    "zathura-pdf-mupdf"
    "telegram-desktop"
    "torbrowser-launcher"
    "openvpn"
    "protonvpn-cli-ng"
    "virtualbox"
    "virtualbox-host-modules-arch"
    "virtualbox-guest-iso"
    "obs-studio"
)

declare -a development_tools=(
    "neovim"
    "python"
    "python-pynvim"
    "npm"
    "python-virtualenv"
    "pyright"
    "debugpy"
    "go"
    "base-devel"
    "gcc"
)

declare -a tmux_plugins=(
    "tmux"
    "bc"
    "jq"
    "gh"
    "glab"
    "playerctl"
)

declare -a terminal_shell=(
    "kitty"
    "zsh"
    "pokemon-colorscripts-git"
)

declare -a fonts_symbols=(
    "noto-fonts"
    "noto-fonts-extra"
    "noto-fonts-emoji"
    "noto-fonts-cjk"
    "ttf-nerd-fonts-symbols"
    "ttf-nerd-fonts-symbols-mono"
)

# Función para instalar los paquetes de un grupo
install_group() {
    local group_name=$1
    shift
    local packages=("$@")
    local install_all=$install_all

    show_info "Instalando grupo de paquetes: $group_name"
    for pkg in "${packages[@]}"; do
        if install_package "$pkg" "$install_all"; then
            if pacman -Qs $pkg > /dev/null; then
                installed+=("$pkg (pacman)")
            else
                installed+=("$pkg (yay)")
            fi
        elif [ $? -eq 2 ]; then
            user_skipped+=("$pkg")
        else
            errors+=("$pkg")
        fi
    done
}

# Función para instalar todos los grupos de paquetes
install_packages() {
    local install_all=$1

    installed=()
    skipped=()
    user_skipped=()
    errors=()

    install_group "Herramientas de Gestión de Dotfiles" "${dotfiles_tools[@]}"
    install_group "Utilidades Básicas del Sistema" "${system_utilities[@]}"
    install_group "Herramientas de Desarrollo y Python" "${development_tools[@]}"
    install_group "Tmux y Gestores de Plugins" "${tmux_plugins[@]}"
    install_group "Terminal y Shell" "${terminal_shell[@]}"
    install_group "Fuentes y Símbolos" "${fonts_symbols[@]}"

    check_and_install_font
    install_additional_tools
    show_summary
}

# Función para instalar herramientas adicionales (Tmux Plugin Manager, NvChad, Starship, Oh My Zsh)
install_additional_tools() {
    # Instalación de Tmux Plugin Manager (tpm)
    show_info "Instalando Tmux Plugin Manager (tpm)..."
    if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
        if [ $? -ne 0 ]; then
            show_error "Error al instalar tmux plugin manager (tpm)."
            errors+=("tpm")
        else
            show_success "Tmux Plugin Manager instalado con éxito."
            installed+=("tpm")
        fi
    else
        show_info "Tmux Plugin Manager ya está instalado."
        skipped+=("tpm")
    fi

    # Instalación de NvChad
    show_info "Instalando NvChad..."
    if [ ! -d "$HOME/.config/nvim" ]; then
        git clone https://github.com/NvChad/starter ~/.config/nvim
        if [ $? -ne 0 ]; then
            show_error "Error al instalar NvChad."
            errors+=("NvChad")
        else
            show_success "NvChad instalado con éxito."
            installed+=("NvChad")
        fi
    else
        show_info "NvChad ya está instalado."
        skipped+=("NvChad")
    fi

    # Instalación de Starship
    show_info "Instalando Starship..."
    if ! command -v starship > /dev/null; then
        curl -sS https://starship.rs/install.sh | sh -s -- --yes
        if [ $? -ne 0 ]; then
            show_error "Error al instalar Starship."
            errors+=("Starship")
        else
            show_success "Starship instalado con éxito."
            installed+=("Starship")
        fi
    else
        show_info "Starship ya está instalado."
        skipped+=("Starship")
    fi

    # Instalación de Oh My Zsh
    show_info "Instalando Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        if [ $? -ne 0 ]; then
            show_error "Error al instalar Oh My Zsh."
            errors+=("Oh My Zsh")
        else
            show_success "Oh My Zsh instalado con éxito."
            installed+=("Oh My Zsh")
        fi
    else
        show_info "Oh My Zsh ya está instalado."
        skipped+=("Oh My Zsh")
    fi
}

# Función para mostrar el resumen de la instalación
show_summary() {
    show_info "-------------------------------------------"
    show_info "Resumen de la instalación"
    show_info "-------------------------------------------"
    show_info "Paquetes instalados:"
    for item in "${installed[@]}"; do
        show_success " - $item"
    done
    show_info "Paquetes ya estaban instalados:"
    for item in "${skipped[@]}"; do
        show_info " - $item"
    done
    show_info "Paquetes omitidos por el usuario:"
    for item in "${user_skipped[@]}"; do
        show_info " - $item"
    done
    show_info "Paquetes que fallaron:"
    for item in "${errors[@]}"; do
        show_error " - $item"
    done
}

# Preguntar si se desea instalar todo de una vez o uno por uno
read -p "¿Quieres instalar todos los paquetes de corrido? [s/n]: " install_all
if [[ $install_all =~ ^[Ss]$ ]]; then
    install_packages true
else
    install_packages false
fi
