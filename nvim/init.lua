-- Use the terminal's clipboard when no graphical clipboard is available.
-- Set this before LazyVim initializes Neovim's clipboard provider.
vim.g.clipboard = "osc52"
vim.opt.clipboard = "unnamedplus"

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
