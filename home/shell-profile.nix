{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "${pkgs.eza}/bin/eza --icons always";
      lg = "${pkgs.lazygit}/bin/lazygit";
      l = "${pkgs.eza}/bin/eza -lah --icons always";
      ll = "${pkgs.eza}/bin/eza -l --icons always";
      la = "${pkgs.eza}/bin/eza -a --icons always";
      lt = "${pkgs.eza}/bin/eza --tree --icons always";
      lla = "${pkgs.eza}/bin/eza -la --icons always";
    };
  };
}
