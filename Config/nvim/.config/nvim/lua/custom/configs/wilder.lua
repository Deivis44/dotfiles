-- ~/.config/nvim/lua/custom/configs/wilder.lua

-- Intentar cargar Wilder.nvim
local status_ok, wilder = pcall(require, "wilder")
if not status_ok then
  vim.notify("Wilder.nvim no pudo ser cargado", vim.log.levels.ERROR)
  return
end

-- =========================
-- Activar Wilder en la línea de comandos
-- =========================
vim.cmd([[
  call wilder#enable_cmdline_enter()
]])

-- =========================
-- Configuración principal
-- =========================
wilder.setup({
  modes = { ':' },   -- Habilitar en comandos (:), búsquedas (/ y ?), etc.
})

-- =========================
-- Renderer: menú emergente con bordes y sin fondo
-- =========================
wilder.set_option('renderer', wilder.popupmenu_renderer({
  max_height    = 10,            -- Máximo de resultados visibles
  popup_border  = 'double',      -- Bordes: 'rounded', 'single', 'double', etc.
  left          = { ' ', wilder.popupmenu_devicons() },   -- Iconos al inicio
  right         = { ' ', wilder.popupmenu_scrollbar() },  -- Barra de desplazamiento
  highlighter   = wilder.basic_highlighter(),             -- Resaltado de coincidencias
  highlights    = {
    border = 'WilderBorder',     -- Aplicar estilo solo al borde
  },
}))

-- =========================
-- Pipelines: fuente de sugerencias
-- =========================
wilder.set_option('pipeline', {
  wilder.branch(
    -- Autocompletado de comandos con búsqueda difusa
    wilder.cmdline_pipeline({
      fuzzy = 1,
    }),
    -- Búsqueda avanzada usando Python
    wilder.python_search_pipeline({
      pattern = wilder.python_fuzzy_pattern(),
    })
  ),
})

-- =========================
-- Colores personalizados
-- =========================
vim.cmd([[
  hi WilderBorder guifg=#56b6c2 guibg=NONE  " Borde en cian, fondo transparente
]])

