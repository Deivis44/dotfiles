-- ~/.config/nvim/lua/custom/plugins.lua

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

  -- Snippets
  { 'L3MON4D3/LuaSnip', lazy = false },
  { 'saadparwaiz1/cmp_luasnip', lazy = false },

  -- Otros plugins necesarios
  { 'vim-python/python-syntax', lazy = false },
  { 'jpalardy/vim-slime', lazy = false },
}
 
