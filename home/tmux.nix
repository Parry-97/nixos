# Tmux: binary from the system profile, config out-of-store and editable in
# `home/dotfiles-tmux/tmux.conf`. Plugins are delivered from nixpkgs by Home
# Manager into ~/.config/tmux/plugins.conf (run-shell lines only).
{
  pkgs,
  lib,
  config,
  ...
}:

{
  programs.tmux = {
    enable = true;
    newSession = true;
    secureSocket = true;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
      continuum
      vim-tmux-navigator
      yank
    ];
  };

  # tmux-yank's system-clipboard backend (wl-copy) — NixOS has no xclip/xsel.
  home.packages = [ pkgs.wl-clipboard ];

  # Replace the Home Manager generated tmux.conf with the out-of-store
  # symlink below so it can be edited without a rebuild. (mkForce beats the
  # module's generated `.text`.)
  xdg.configFile."tmux/plugins.conf".text = lib.concatMapStringsSep "\n\n" (p: "run-shell ${p.rtp}") (
    with pkgs.tmuxPlugins;
    [
      sensible
      resurrect
      continuum
      vim-tmux-navigator
      yank
    ]
  );

  xdg.configFile."tmux/tmux.conf".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/home/dotfiles-tmux/tmux.conf"
  );
}
