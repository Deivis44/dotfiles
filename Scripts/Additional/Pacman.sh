#!/bin/bash

# Mostrar banner de inicio del script
echo -e "\e[1;32mIniciando configuración de pacman en Arch Linux...\e[0m"

# Función para habilitar "I Love Candy" en pacman.conf
enable_i_love_candy() {
    echo "Configurando 'I Love Candy' en pacman.conf..."

    if grep -q "^ILoveCandy" /etc/pacman.conf; then
        echo "'I Love Candy' ya está activado en pacman.conf."
    else
        echo "Activando 'I Love Candy' en pacman.conf..."
        echo "ILoveCandy" | sudo tee -a /etc/pacman.conf
    fi
}

# Función para habilitar ParallelDownloads en pacman.conf
enable_parallel_downloads() {
    echo "Configurando descargas paralelas en pacman.conf..."

    if grep -q "^#ParallelDownloads" /etc/pacman.conf; then
        sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
        echo "Descargas paralelas activadas en pacman.conf."
    elif grep -q "^ParallelDownloads" /etc/pacman.conf; then
        echo "Descargas paralelas ya están activadas en pacman.conf."
    else
        echo "ParallelDownloads=5" | sudo tee -a /etc/pacman.conf
        echo "Descargas paralelas configuradas en pacman.conf."
    fi
}

# Función para habilitar el repositorio multilib
enable_multilib() {
    echo "Habilitando repositorio multilib en pacman.conf..."

    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo "El repositorio 'multilib' ya está habilitado en pacman.conf."
    else
        # Descomentar las líneas necesarias
        sudo sed -i '/#\[multilib\]/,/^#Include/s/^#//' /etc/pacman.conf
        echo "Repositorio 'multilib' habilitado en pacman.conf."
    fi
}

# Función para actualizar mirrorlist usando servidores cercanos a Colombia
update_mirrorlist() {
    echo "Actualizando mirrorlist con los servidores más rápidos en América Latina..."

    # Verificar si reflector está instalado, si no, instalarlo
    if ! command -v reflector &> /dev/null; then
        echo "El paquete 'reflector' no está instalado. Instalándolo ahora..."
        sudo pacman -S reflector --noconfirm
    fi

    # Ejecutar reflector para obtener los servidores más rápidos en América Latina y actualizarlos en mirrorlist
    sudo reflector --country 'Colombia,Brazil,Argentina,Chile,Peru' --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    if [ $? -eq 0 ]; then
        echo "Mirrorlist actualizado exitosamente con los servidores más rápidos en América Latina."
    else
        echo "Error al actualizar mirrorlist. Verifique su conexión o la configuración de reflector."
    fi
}

# Función para instalar paquetes esenciales
install_essential_packages() {
    echo "Instalando paquetes esenciales: git, base-devel..."

    # Paquetes esenciales
    PACKAGES=(git base-devel)

    # Instalación de los paquetes
    for package in "${PACKAGES[@]}"; do
        if pacman -Qi $package &> /dev/null; then
            echo "$package ya está instalado."
        else
            echo "Instalando $package..."
            sudo pacman -S $package --noconfirm
        fi
    done
}

# Ejecutar funciones en orden
enable_i_love_candy
enable_parallel_downloads
enable_multilib
update_mirrorlist
install_essential_packages

# Mensajes finales
echo -e "\e[1;32mConfiguración de pacman completada.\e[0m"

