{
  pkgs,
  lib,
  config,
  ...
}:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Inject binaries into Neovim's PATH without cluttering your system profile
    extraPackages = with pkgs; [
      # 1. Compilers & Build Tools (Required for Treesitter parser compilation)
      gcc
      cmake
      tree-sitter # Fixes "tree-sitter (CLI) is not installed"
      gnumake

      # --- 2. SNACKS.NVIM EXTRA TOOLS (Fixes Snacks Warnings) ---
      imagemagick # Fixes missing 'magick' tool for terminal images
      ghostscript # Fixes missing 'gs' tool for PDF rendering
      sqlite # Fixes missing SQLite3 for picker history

      # 2. Search Tools (Required for Telescope / Snacks.nvim / Flash)
      ripgrep
      fd
      fzf

      # 3. Language Servers (LSPs)
      nixd # Nix LSP
      lua-language-server # Lua LSP
      rust-analyzer # Rust LSP
      pyright # Python LSP
      gopls # Go LSP
      markdownlint-cli2
      markdown-toc
      # vscode-langservers-extracted # HTML/CSS/JSON LSPs
      # tailwindcss-language-server

      # 4. Formatters & Linters
      stylua # Lua formatter
      nixfmt # Nix formatter
      # prettierd             # JS/TS/Markdown formatter
    ];
  };

  # OPTIONAL: If you want Home Manager to manage your ~/.config/nvim folder from your flake:
  xdg.configFile."nvim/init.lua".enable = lib.mkForce false;
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/home/dotfiles/nvim";
  # xdg.configFile."nvim".source = ./dotfiles/nvim;
}
