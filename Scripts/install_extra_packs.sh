#!/bin/bash

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

# Función para instalar un paquete si es necesario
install_package_if_needed() {
    local pkg=$1
    if ! command -v "$pkg" > /dev/null; then
        show_info "$pkg no está instalado. Instalándolo..."
        sudo pacman -S --noconfirm "$pkg" || yay -S --noconfirm "$pkg"
    else
        show_info "$pkg ya está instalado."
    fi
}

# Tmux Plugin Manager (TPM) instalación
install_tpm() {
    install_package_if_needed "tmux"
    if command -v tmux > /dev/null && ask_install "Tmux Plugin Manager (TPM)"; then
        show_info "Instalando Tmux Plugin Manager (tpm)..."
        if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
            git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
            show_success "tpm instalado con éxito en ~/.config/tmux/plugins/tpm"
        else
            show_info "tpm ya está instalado en ~/.config/tmux/plugins/tpm"
        fi
    fi
}

# NvChad instalación con verificación de Neovim
install_nvchad() {
    install_package_if_needed "neovim"
    if command -v nvim > /dev/null && ask_install "NvChad (configuración de Neovim)"; then
        show_info "Instalando NvChad..."
        git clone https://github.com/NvChad/starter "~/.config/nvim"
        show_success "NvChad instalado con éxito en ~/.config/nvim"
    fi
}

# Starship instalación
install_starship() {
    if ask_install "Starship (prompt personalizado)"; then
        show_info "Instalando Starship..."
        if ! command -v starship > /dev/null; then
            curl -sS https://starship.rs/install.sh | sh -s -- --yes
            show_success "Starship instalado con éxito."
        else
            show_info "Starship ya está instalado."
        fi
    fi
}

# Doom en la terminal instalación
install_doom_terminal() {
    if ask_install "Doom en la Terminal"; then
        install_package_if_needed "kitty"
        install_package_if_needed "zig"
        
        if [ ! -d "$HOME/terminal-doom" ]; then
            show_info "Instalando Doom en la terminal..."
            git clone https://github.com/cryptocode/terminal-doom.git "$HOME/terminal-doom"
            cd "$HOME/terminal-doom"
            zig build -Doptimize=ReleaseFast
            if [ $? -eq 0 ]; then
                show_success "Doom en la terminal instalado con éxito en $HOME/terminal-doom"
                echo -e "\e[1;32mPara ejecutar Doom en la terminal, puedes añadir el siguiente alias a tu archivo .zshrc:\nalias doom-zig='$HOME/terminal-doom/zig-out/bin/terminal-doom'\e[0m"
            else
                show_error "Error al construir Doom en la terminal."
            fi
            cd -
        else
            show_info "Doom en la terminal ya está instalado en $HOME/terminal-doom"
        fi
    fi
}

# Spicetify instalación
install_spicetify() {
    if ask_install "Spicetify"; then
        if command -v spotify-launcher > /dev/null; then
            if ! command -v spicetify > /dev/null; then
                show_info "Instalando Spicetify..."
                curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
                show_success "Spicetify instalado con éxito."
            else
                show_info "Spicetify ya está instalado."
            fi
        else
            show_error "Spotify-launcher no está instalado. Spicetify no puede instalarse sin Spotify."
        fi
    fi
}

# Ejecutar instalaciones adicionales
show_info "Instalación de herramientas adicionales..."
install_tpm
install_nvchad
install_starship
install_doom_terminal
install_spicetify
show_success "Instalación de herramientas adicionales completada."

