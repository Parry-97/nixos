return {
  {
    "Sarctiann/mojo.nvim",
    main = "mojo",
    opts = {
      terminal = { enabled = true, auto_activate = false },
      lsp = {
        root_markers = { "pyproject.toml", "magic.toml", "pixi.toml", ".git" },
      },
      completion = { enabled = true },
      format = { enabled = true },
      statusline = { enabled = true },
      commands = { master = true, spread = false },
    },
  },
}
