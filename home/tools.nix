{ ... }:

{
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
  };

  programs.bat.enable = true;

  programs.atuin = {
    enable = true;
    flags = [ "--disable-ctrl-r" ];
    enableNushellIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
  };
}
