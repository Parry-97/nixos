{ pkgs, ... }:

{
  imports = [
    ./shell-profile.nix
    ./tools.nix
    ./neovim.nix
    ./opencode.nix
    ./sbx.nix
  ];
  home.sessionPath = [
    "/home/pops/.local/bin"

  ];

  home.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

  # Home Manager requirements
  home.username = "pops";
  home.homeDirectory = "/home/pops";
  home.stateVersion = "26.05";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
