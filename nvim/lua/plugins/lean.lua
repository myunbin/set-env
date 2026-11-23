return {
  {
    "Julian/lean.nvim",
    -- Load at startup so leanls is enabled before directory/session buffers
    -- restore. This avoids an infoview stuck at "Processing file..." when
    -- Neovim is launched with a project directory instead of a Lean file.
    lazy = false,
    init = function()
      vim.g.lean_config = {
        mappings = true,
        infoview = {
          autoopen = true,
        },
      }

      -- Avoid asking Lean to reprocess the file on every single keystroke.
      vim.lsp.config("leanls", {
        init_options = {
          editDelay = 100,
        },
      })
    end,
  },
}
