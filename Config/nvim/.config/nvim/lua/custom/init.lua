-- ~/.config/nvim/lua/custom/init.lua

-- Mensaje de bienvenida
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.notify("Hola deivi! ;^}", "info", { title = "Bienvenido a Neovim" })
  end,
})

-- Configuración de Python y vim-slime
vim.g.python3_host_prog = '/usr/bin/python3'
vim.g.slime_target = "tmux"
vim.g.slime_default_config = { socket_name = "default", target_pane = "{last}" }
vim.g.slime_dont_ask_default = 1

-- Configuración de Mason y LSP
require("mason").setup()
require("mason-lspconfig").setup {
  ensure_installed = { "pyright", "ts_ls", "html", "cssls", "bashls", "jsonls", "yamlls", "gopls", "clangd", "rust_analyzer", "lua_ls" },
}

local lspconfig = require("lspconfig")
local cmp = require("cmp")
local luasnip = require("luasnip")
local notify = require("notify")

-- Configuración del plugin `notify`
notify.setup({
  background_colour = "#000000",
})
vim.notify = notify

-- Configuración de cmp
cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = {
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' },
  },
}

-- Configuración de LSP
local on_attach = function(_, bufnr)
  local opts = { noremap = true, silent = true }
  local keymap = vim.api.nvim_buf_set_keymap
  local mappings = {
    ['n'] = {
      ['gd'] = '<cmd>lua vim.lsp.buf.definition()<CR>',
      ['K'] = '<cmd>lua vim.lsp.buf.hover()<CR>',
      ['gi'] = '<cmd>lua vim.lsp.buf.implementation()<CR>',
      ['<C-k>'] = '<cmd>lua vim.lsp.buf.signature_help()<CR>',
      ['<space>wa'] = '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>',
      ['<space>wr'] = '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>',
      ['<space>wl'] = '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>',
      ['<space>D'] = '<cmd>lua vim.lsp.buf.type_definition()<CR>',
      ['<space>rn'] = '<cmd>lua vim.lsp.buf.rename()<CR>',
      ['<space>ca'] = '<cmd>lua vim.lsp.buf.code_action()<CR>',
      ['gr'] = '<cmd>lua vim.lsp.buf.references()<CR>',
      ['<space>e'] = '<cmd>lua vim.diagnostic.open_float()<CR>',
      ['[d'] = '<cmd>lua vim.diagnostic.goto_prev()<CR>',
      [']d'] = '<cmd>lua vim.diagnostic.goto_next()<CR>',
      ['<space>q'] = '<cmd>lua vim.diagnostic.setloclist()<CR>',
      ['<space>f'] = '<cmd>lua vim.lsp.buf.format({ async = true })<CR>',
    },
  }
  for mode, maps in pairs(mappings) do
    for key, cmd in pairs(maps) do
      keymap(bufnr, mode, key, cmd, opts)
    end
  end
end

local servers = { "pyright", "ts_ls", "html", "cssls", "bashls", "jsonls", "yamlls", "gopls", "clangd", "rust_analyzer", "lua_ls" }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 150,
    }
  }
end

-- Configuración de DAP y DAP-UI
local dap = require('dap')
local dapui = require('dapui')

require('dap-python').setup('~/.virtualenvs/debugpy/bin/python')
require('dap-go').setup()
dapui.setup()

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
  notify("Debugging started", "info", { title = "DAP" })
end

dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
  notify("Debugging terminated", "info", { title = "DAP" })
end

dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
  notify("Debugging exited", "info", { title = "DAP" })
end

dap.listeners.before.event_stopped["dapui_config"] = function()
  notify("Breakpoint hit", "info", { title = "DAP" })
end

-- Asignación de teclas para DAP
vim.api.nvim_set_keymap('n', '<F5>', '<Cmd>lua require"dap".continue()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F10>', '<Cmd>lua require"dap".step_over()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F11>', '<Cmd>lua require"dap".step_into()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F12>', '<Cmd>lua require"dap".step_out()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>b', '<Cmd>lua require"dap".toggle_breakpoint()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>B', '<Cmd>lua require"dap".set_breakpoint(vim.fn.input("Breakpoint condition: "))<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>lp', '<Cmd>lua require"dap".set_breakpoint(nil, nil, vim.fn.input("Log point message: "))<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>dr', '<Cmd>lua require"dap".repl.open()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>dl', '<Cmd>lua require"dap".run_last()<CR>', { noremap = true, silent = true })

-- Configuración de LazyGit
vim.api.nvim_set_keymap('n', '<leader>gg', ':LazyGit<CR>', { noremap = true, silent = true })

-- Configuración del menú de contexto con el mouse
vim.keymap.set("n", "<RightMouse>", function()
  local options = vim.bo.ft == "NvimTree" and "nvimtree" or "default"
  require("menu").open(options, { mouse = true })
end, { noremap = true, silent = true })

require("custom.configs.wilder")
