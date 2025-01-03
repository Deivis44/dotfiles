return {
  -- GitHub Copilot
  { 'github/copilot.vim', lazy = false },

  -- LSP Configuración
  { 'neovim/nvim-lspconfig', lazy = false },
  {
    'williamboman/mason.nvim',
    opts = {
      ensure_installed = {
        "black",
        "debugpy",
        "mypy",
        "ruff-lsp",
      },
    },
    lazy = false
  },
  { 'williamboman/mason-lspconfig.nvim', lazy = false },

  -- Autocompletado
  { 'hrsh7th/nvim-cmp', lazy = false },
  { 'hrsh7th/cmp-nvim-lsp', lazy = false },
  { 'hrsh7th/cmp-buffer', lazy = false },
  { 'hrsh7th/cmp-path', lazy = false },
  { 'hrsh7th/cmp-cmdline', lazy = false },
  { 'hrsh7th/cmp-nvim-lua', lazy = false },

  -- Snippets
  { 'L3MON4D3/LuaSnip', lazy = false },
  { 'saadparwaiz1/cmp_luasnip', lazy = false },
  { 'rafamadriz/friendly-snippets', lazy = false },

  -- Otros Plugins Necesarios
  { 'vim-python/python-syntax', lazy = false },
  { 'jpalardy/vim-slime', lazy = false },
  { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate', lazy = false },
  { 'nvim-lua/plenary.nvim', lazy = false },
  { 'numToStr/Comment.nvim', lazy = false },

  -- Compilación, Ejecución y Depuración
  {
    "mfussenegger/nvim-dap",
    config = function()
      local mappings = require("custom.mappings")
      for key, mapping in pairs(mappings.dap.n) do
        vim.keymap.set("n", key, mapping[1], { noremap = true, silent = true })
      end
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end
  },
  { 'nvim-telescope/telescope-dap.nvim', requires = {'nvim-telescope/telescope.nvim', 'mfussenegger/nvim-dap'}, lazy = false },
  { 'leoluz/nvim-dap-go', requires = {'mfussenegger/nvim-dap'}, lazy = false },
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
    },
    config = function()
      local path = "~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"
      require("dap-python").setup(path)

      local mappings = require("custom.mappings")
      for key, mapping in pairs(mappings.dap_python.n) do
        if type(mapping[1]) == "function" then
          vim.keymap.set("n", key, mapping[1], { noremap = true, silent = true })
        else
          vim.keymap.set("n", key, mapping[1], { noremap = true, silent = true })
        end
      end
    end,
  },
  -- Notificaciones
  { 'rcarriga/nvim-notify', lazy = false },

  -- nvim-nio para soporte de nvim-dap-ui
  { 'nvim-neotest/nvim-nio', lazy = false },
  
  -- Plugin LazyGit para integración con Git
  { 'kdheepak/lazygit.nvim', lazy = false },

  -- Menu Plugin
  { "nvzone/volt", lazy = true },
  { "nvzone/menu", lazy = true },

  { "nvzone/timerly", cmd = "TimerlyToggle" },

  -- null-ls.nvim (Configuración de LSP para linters y formatters)
  {
    "nvimtools/none-ls.nvim",
    ft = {"python"},
    opts = function()
      return require "custom.configs.null-ls"
    end,
  },
  {
    "gelguy/wilder.nvim",
    lay = false,

    requires = { "romgrk/fzy-lua-native" },
    config = function()
      local ok, _ = pcall(require, "custom.configs.wilder")
    end,
  },
}

