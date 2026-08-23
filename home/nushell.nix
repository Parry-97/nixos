{ ... }:

{
  programs.nushell = {
    enable = true;
    shellAliases = {
      lg = "lazygit";
      l = "eza -la --icons auto";
      ll = "eza -l --icons auto";
      la = "eza -a --icons auto";
      lt = "eza --tree --icons auto";
      lla = "eza -la --icons auto";
      rip = "shred -vzu -n5";
    };
    environmentVariables = {
      KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    };
    settings = {
      show_banner = false;
      completions.external.enable = true;
      completions.external.max_results = 100;
    };
    extraConfig = ''
      def v [] {
        let files = (fd --type f --hidden --exclude .git --exclude node_modules
          | fzf --multi --preview 'bat --color=always --style=numbers --line-range :300 {}')
        if not ($files | is-empty) { nvim ...($files | split row "\n") }
      }
    '';
  };
}
