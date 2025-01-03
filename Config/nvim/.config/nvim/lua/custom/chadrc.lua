-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "ashes",
  theme_togle = {},
  transparency = true,
}

M.ui = {
  telescope = { style = "bordered" },
  statusline = { theme = "minimal" },

  cmp = {
    icons_left = true,
    style = "default",
  },
}

M.nvdash = {
  load_on_startup = true,
  header = {
    "                                   ",
    "    ▓█████▄  ███▄ ▄███▓▒███████▒   ",
    "    ▒██▀ ██▌▓██▒▀█▀ ██▒▒ ▒ ▒ ▄▀░   ",
    "    ░██   █▌▓██    ▓██░░ ▒ ▄▀▒░    ",
    "    ░▓█▄   ▌▒██    ▒██   ▄▀▒   ░   ",
    "    ░▒████▓ ▒██▒   ░██▒▒███████▒   ",
    "     ▒▒▓  ▒ ░ ▒░   ░  ░░▒▒ ▓░▒░▒   ",
    "     ░ ▒  ▒ ░  ░      ░░░▒ ▒ ░ ▒   ",
    "     ░ ░  ░ ░      ░   ░ ░ ░ ░ ░   ",
    "       ░           ░     ░ ░       ",
    "     ░                 ░           ",
    "                                   ",
    "         Powered By  eovim       ",
    "                                   ",
    "                                   ",
  },

  --header = {
    --"                                   ",
    --"                                   ",
    --"                                   ",
    --"                                   ",
    --"                                   ",
    --"                                   ",
    --"                                   ",
    --"                                   ",
    --"                                   ",
    --"         Powered By  eovim       ",
    --"                                   ",
  --},
}

return M

