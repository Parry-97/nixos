{ ... }:

{
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
  };

  programs.bat.enable = true;
  programs.atuin.enable = true;
  programs.atuin.flags = [ "--disable-ctrl-r" ];
}
