return {
  {
    "benknoble/vim-dafny",
    ft = "dafny",
    init = function()
      vim.filetype.add({
        extension = {
          dfy = "dafny",
        },
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        dafny = {},
      },
    },
  },
}
