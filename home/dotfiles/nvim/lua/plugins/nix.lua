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
              nixpkgs = {
                expr = "import <nixpkgs> { }",
              },
              options = {
                nixos = {
                  expr = '(builtins.getFlake "/home/pops/.config/nixos").nixosConfigurations.nixos.options',
                },

                home_manager = {
                  expr = '(builtins.getFlake "/home/pops/.config/nixos").homeConfigurations.pops.options',
                },
              },
            },
          },
        },
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
