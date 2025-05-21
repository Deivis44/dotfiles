-- mappings.lua
local M = {}

-- ============================================================================
-- Core DAP mappings
-- ============================================================================
M.dap = {
  plugin = true,
  n = {
    -- Toggle breakpoint
    ["<leader>db"] = { "<cmd> DapToggleBreakpoint <CR>", "Toggle Breakpoint" },
  },
}

-- ============================================================================
-- DAP UI mappings
-- ============================================================================
M.dap_ui = {
  plugin = true,
  n = {
    -- Mostrar/ocultar interfaz DAP UI
    ["<leader>du"] = { "<cmd>lua require('dapui').toggle()<CR>", "Toggle DAP UI" },
  },
}

-- ============================================================================
-- DAP Python mappings
-- ============================================================================
M.dap_python = {
  plugin = true,
  ft = "python",  -- solo activa estos mapeos en archivos Python
  n = {
    -- Ejecutar test_method() de dap-python
    ["<leader>dpr"] = {
      function()
        require('dap-python').test_method()
      end,
      "DAP: Run Python Method Test",
    },
  },
}

return M

