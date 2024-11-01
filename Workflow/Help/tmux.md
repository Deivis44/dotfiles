# Configuración de Comandos de Tmux

Este documento describe los comandos básicos y personalizados de **tmux** basados en tu configuración actual. Se cubren tanto los comandos con prefijo como los comandos sin prefijo, además de incluir los comandos relacionados con plugins y modos de copia.

## Comandos Básicos y Esenciales de Tmux

### Prefijo
En tu configuración, el prefijo de **tmux** se ha cambiado a `Alt + q` (`M-q`). Por lo tanto, todos los comandos con prefijo comenzarán con `Alt + q`.

### Comandos con Prefijo (Alt + q)

| Comando                   | Descripción                                          |
|---------------------------|------------------------------------------------------|
| Alt + q "                 | Dividir el panel actual verticalmente y mantener el directorio actual |
| Alt + q @                 | Dividir el panel actual horizontalmente y mantener el directorio actual |
| Alt + q c                 | Crear una nueva ventana                              |
| Alt + q ,                 | Renombrar la ventana actual                          |
| Alt + q &                 | Cerrar la ventana actual                             |
| Alt + q d                 | Desvincular la sesión actual                         |
| Alt + q $                 | Renombrar la sesión actual                           |
| Alt + q w                 | Listar todas las ventanas                            |
| Alt + q f                 | Buscar una ventana                                   |
| Alt + q x                 | Cerrar el panel actual                               |
| Alt + q :                 | Entrar en el modo de comando                         |
| Alt + q q                 | Mostrar números de los paneles                       |
| Alt + q r                 | Recargar la configuración de tmux                    |
| Alt + q R                 | Renombrar el panel actual                            |

### Comandos sin Prefijo

| Comando                   | Descripción                                          |
|---------------------------|------------------------------------------------------|
| h                         | Moverse al panel izquierdo                           |
| j                         | Moverse al panel inferior                            |
| k                         | Moverse al panel superior                            |
| l                         | Moverse al panel derecho                             |
| Alt + Left                | Moverse al panel izquierdo                           |
| Alt + Right               | Moverse al panel derecho                             |
| Alt + Up                  | Moverse al panel superior                            |
| Alt + Down                | Moverse al panel inferior                            |
| Shift + Left              | Cambiar a la ventana anterior                        |
| Shift + Right             | Cambiar a la ventana siguiente                       |
| Alt + H                   | Cambiar a la ventana anterior                        |
| Alt + L                   | Cambiar a la ventana siguiente                       |

### Modo de Copia (Copiar y Seleccionar Texto)

Para copiar texto, primero necesitas entrar al **modo de copia** con el prefijo (`Alt + q`):

| Comando                   | Descripción                                          |
|---------------------------|------------------------------------------------------|
| Alt + q [                 | Entrar al modo de copia                              |
| v                         | Iniciar selección en modo de copia                   |
| Ctrl + v                  | Alternar selección rectangular en modo de copia      |
| y                         | Copiar selección y salir del modo de copia           |
| Alt + q ]                 | Pegar desde el portapapeles                          |

### Comandos Relacionados con Plugins

**Tmux-resurrect** y **tmux-continuum** están configurados en tu **tmux.conf** para guardar y restaurar sesiones automáticamente. Los siguientes comandos te permiten controlar estos plugins:

| Comando                   | Descripción                                          |
|---------------------------|------------------------------------------------------|
| Alt + q I                 | Instalar plugins (usar con TPM)                      |
| Alt + q U                 | Actualizar plugins (usar con TPM)                    |
| Alt + q u                 | Deshacer el último guardado de tmux-resurrect        |
| Alt + q r                 | Restaurar la última sesión guardada con tmux-resurrect |
| Alt + q s                 | Guardar la sesión actual con tmux-resurrect          |

### Comandos Adicionales y Funciones Principales

| Comando                   | Descripción                                          |
|---------------------------|------------------------------------------------------|
| Alt + q t                 | Mostrar el reloj                                     |
| Alt + q l                 | Alternar entre la última y la ventana actual         |
| Alt + q N                 | Cambiar a la ventana siguiente                       |
| Alt + q P                 | Cambiar a la ventana anterior                        |

### Recarga de Configuración

Para recargar la configuración de **tmux** después de realizar cambios en el archivo de configuración (`~/.config/tmux/tmux.conf`), usa:

| Comando                   | Descripción                                          |
|---------------------------|------------------------------------------------------|
| Alt + q r                 | Recargar el archivo de configuración y mostrar un mensaje |

### Descripción de Plugins

#### 1. **Tmux Plugin Manager (TPM)**
- **Atajos**: 
  - `Alt + q I`: Instalar plugins.
  - `Alt + q U`: Actualizar plugins.
- **Descripción**: Permite instalar, actualizar y gestionar plugins de **tmux** directamente desde el archivo de configuración.

#### 2. **Tmux-Resurrect**
- **Atajos**:
  - `Alt + q s`: Guardar la sesión actual.
  - `Alt + q r`: Restaurar la sesión anterior.
- **Descripción**: Guarda y restaura el estado de tus sesiones de **tmux**, incluyendo paneles, ventanas, directorios y más.

#### 3. **Tmux-Continuum**
- **Descripción**: Guarda automáticamente tus sesiones cada cierto tiempo (configurado para guardar cada 15 minutos).

#### 4. **Tmux-Vim Navigator**
- **Descripción**: Facilita la navegación entre paneles de **tmux** y ventanas de Vim usando las teclas `h`, `j`, `k`, `l` al estilo Vim.

### Atajo para renombrar el panel actual
Para renombrar un panel, se ha añadido el atajo `Alt + q R` en tu configuración, que te permite cambiar el nombre del panel activo rápidamente.

---

Este README cubre los comandos y funcionalidades principales de **tmux** según tu configuración actual. Puedes modificarlo para adaptarlo a cualquier cambio futuro en tu archivo de configuración.

