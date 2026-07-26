{ pkgs, ... }:

{
  imports = [
    ./shell-profile.nix
    ./tools.nix
  ];

  # Home Manager requirements
  home.username = "pops";
  home.homeDirectory = "/home/pops";
  home.stateVersion = "26.05";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
