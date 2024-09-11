return {
  -- GitHub Copilot
  { 'github/copilot.vim', lazy = false },

  -- LSP Configuración
  { 'neovim/nvim-lspconfig', lazy = false },
  { 'williamboman/mason.nvim', lazy = false },
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
  { 'mfussenegger/nvim-dap', lazy = false },
  { 'rcarriga/nvim-dap-ui', requires = {'mfussenegger/nvim-dap'}, lazy = false },
  { 'nvim-telescope/telescope-dap.nvim', requires = {'nvim-telescope/telescope.nvim', 'mfussenegger/nvim-dap'}, lazy = false },
  { 'leoluz/nvim-dap-go', requires = {'mfussenegger/nvim-dap'}, lazy = false },
  { 'mfussenegger/nvim-dap-python', requires = {'mfussenegger/nvim-dap'}, lazy = false },

  -- Notificaciones
  { 'rcarriga/nvim-notify', lazy = false },

  -- nvim-nio para soporte de nvim-dap-ui
  { 'nvim-neotest/nvim-nio', lazy = false },

  -- Plugin LazyGit para integración con Git
  { 'kdheepak/lazygit.nvim', lazy = false },
}
