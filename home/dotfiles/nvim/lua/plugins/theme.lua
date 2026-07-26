return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true, -- Makes main editor background transparent
      style = "night",
      styles = {
        sidebars = "transparent", -- Keeps sidebars (e.g., Neo-tree) opaque
        floats = "dark", -- Keeps popups (LSP hovers, Telescope/Snacks pickers) opaque
      },
    },
  },
}
