{ pkgs, config, ... }:

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
      rip = "shred -vzu -n5";
    };
    initExtra = ''
      v() {
        local files
        files=$(${pkgs.fd}/bin/fd --type f --hidden --exclude .git --exclude node_modules \
          | ${pkgs.fzf}/bin/fzf --multi --preview '${pkgs.bat}/bin/bat --color=always --style=numbers --line-range :300 {}')
        [[ -n "$files" ]] &&  ${config.programs.neovim.finalPackage}/bin/nvim $files
      }
    '';
  };
}
