return {
  -- =========================
  -- GitHub Copilot
  -- =========================
  {
    "github/copilot.vim",
    lazy = false,
  },

  -- =========================
  -- LSP: Configuración y gestor de servidores
  -- =========================
  {
    "neovim/nvim-lspconfig",
    lazy = false,
  },
  {
    "williamboman/mason.nvim",
    lazy = false,
    opts = {
      ensure_installed = {
        "black",
        "debugpy",
        "mypy",
        "ruff-lsp",
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
  },

  -- =========================
  -- Autocompletado (nvim-cmp)
  -- =========================
  { "hrsh7th/nvim-cmp",     lazy = false },
  { "hrsh7th/cmp-nvim-lsp", lazy = false },
  { "hrsh7th/cmp-buffer",   lazy = false },
  { "hrsh7th/cmp-path",     lazy = false },
  { "hrsh7th/cmp-cmdline",  lazy = false },
  { "hrsh7th/cmp-nvim-lua", lazy = false },

  -- =========================
  -- Snippets
  -- =========================
  { "L3MON4D3/LuaSnip",           lazy = false },
  { "saadparwaiz1/cmp_luasnip",   lazy = false },
  { "rafamadriz/friendly-snippets", lazy = false },

  -- =========================
  -- Sintaxis y utilidades varias
  -- =========================
  { "vim-python/python-syntax", lazy = false },
  { "jpalardy/vim-slime",       lazy = false },

  -- =========================
  -- Treesitter: override para parsers extra
  -- =========================
  {
    "nvim-treesitter/nvim-treesitter",
    override = {
      build = ":TSUpdate",
      opts = {
        ensure_installed = {
          "bash", "c", "cpp", "go", "java", "javascript", "json",
          "lua", "python", "rust", "typescript", "yaml", "html", "css",
          "markdown", "markdown_inline", "latex",
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
      },
    },
  },

  -- =========================
  -- Utilities
  -- =========================
  { "nvim-lua/plenary.nvim", lazy = false },
  { "numToStr/Comment.nvim", lazy = false },

  -- =========================
  -- Depuración y DAP
  -- =========================
  {
    "mfussenegger/nvim-dap",
    lazy = false,
    config = function()
      local mappings = require("custom.mappings")
      for key, mapping in pairs(mappings.dap.n) do
        vim.keymap.set("n", key, mapping[1], { noremap = true, silent = true })
      end
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    lazy = false,
    dependencies = "mfussenegger/nvim-dap",
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = dapui.open
      dap.listeners.before.event_terminated["dapui_config"] = dapui.close
      dap.listeners.before.event_exited["dapui_config"]    = dapui.close
    end,
  },
  {
    "nvim-telescope/telescope-dap.nvim",
    lazy = false,
    requires = { "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap" },
  },
  { "leoluz/nvim-dap-go", lazy = false, requires = { "mfussenegger/nvim-dap" } },
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    lazy = false,
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
    },
    config = function()
      require("dap-python").setup("~/.virtualenvs/debugpy/bin/python")
      local mappings = require("custom.mappings")
      for key, mapping in pairs(mappings.dap_python.n) do
        vim.keymap.set("n", key, mapping[1], { noremap = true, silent = true })
      end
    end,
  },

  -- =========================
  -- Notificaciones
  -- =========================
  { "rcarriga/nvim-notify", lazy = false },

  -- =========================
  -- Integración nvim-neotest
  -- =========================
  { "nvim-neotest/nvim-nio", lazy = false },

  -- =========================
  -- Git & Menús
  -- =========================
  { "kdheepak/lazygit.nvim", lazy = false },
  { "nvzone/volt",           lazy = true  },
  { "nvzone/menu",           lazy = true  },
  { "nvzone/timerly",        cmd = "TimerlyToggle" },

  -- =========================
  -- Linters y formatters (null-ls)
  -- =========================
  {
    "nvimtools/none-ls.nvim",
    ft   = { "python" },
    opts = function()
      return require("custom.configs.null-ls")
    end,
  },

  -- =========================
  -- Mejoras de UI de comandos (Wilder)
  -- =========================
  {
    "gelguy/wilder.nvim",
    lazy     = true,
    requires = { "romgrk/fzy-lua-native" },
    config   = function()
      pcall(require, "custom.configs.wilder")
    end,
  },

  -- =========================
  -- Markdown: vista enriquecida (render-markdown.nvim)
  -- =========================
  {
    "MeanderingProgrammer/render-markdown.nvim",
    lazy         = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "echasnovski/mini.nvim",
    },
    opts = {},  -- configuración por defecto
  },
}

