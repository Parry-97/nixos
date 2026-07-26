{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "${pkgs.eza}/bin/eza --icons auto";
      lg = "${pkgs.lazygit}/bin/lazygit";
      l = "${pkgs.eza}/bin/eza -la --icons auto";
      ll = "${pkgs.eza}/bin/eza -l --icons auto";
      la = "${pkgs.eza}/bin/eza -a --icons auto";
      lt = "${pkgs.eza}/bin/eza --tree --icons auto";
      lla = "${pkgs.eza}/bin/eza -la --icons auto";
    };
  };
}
