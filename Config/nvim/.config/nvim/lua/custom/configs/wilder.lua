-- ~/.config/nvim/lua/custom/configs/wilder.lua

local status_ok, wilder = pcall(require, "wilder")
if not status_ok then
  vim.notify("Wilder.nvim no pudo ser cargado", "error")
  return
end

-- Activar Wilder
vim.cmd([[
  call wilder#enable_cmdline_enter()
]])

-- Configuración principal de Wilder
wilder.setup({
    modes = { ':'}, -- Habilitar Wilder para comandos, búsqueda y más
})


-- Configuración del renderer con bordes visibles y sin fondo
wilder.set_option('renderer', wilder.popupmenu_renderer({
    max_height = 10, -- Máximo de resultados visibles
    popup_border = 'double', -- Tipo de borde (rounded, single, double, etc.)
    left = { ' ', wilder.popupmenu_devicons() }, -- Iconos opcionales
    right = { ' ', wilder.popupmenu_scrollbar() }, -- Barra de desplazamiento opcional
    highlighter = wilder.basic_highlighter(), -- Resaltado básico
    highlights = {
        border = 'WilderBorder', -- Solo bordes visibles
    },
}))

-- Configuración de pipelines
wilder.set_option('pipeline', {
    wilder.branch(
        wilder.cmdline_pipeline({
            fuzzy = 1, -- Activar búsqueda difusa
        }),
        wilder.python_search_pipeline({
            pattern = wilder.python_fuzzy_pattern(), -- Búsqueda avanzada con Python
        })
    ),
})

-- Definir colores personalizados solo para el borde
vim.cmd([[
  hi WilderBorder guifg=#56b6c2 guibg=NONE
]])
