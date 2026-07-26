return {
  -- 1. Disable Mason on NixOS
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },

  -- 2. Explicitly attach nixd & lua_ls supplied by Nix
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nixd = {
          cmd = { "nixd" },
          settings = {
            nixd = {
              formatting = {
                command = { "nixfmt" },
              },
            },
          },
        },
        lua_ls = {},
      },
    },
  },

  -- 3. Force Treesitter to enable highlighting for Nix, Lua, Bash
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      highlight = { enable = true },
      ensure_installed = { "nix", "lua", "bash", "vim", "vimdoc", "markdown", "rust" },
    },
  },
}
