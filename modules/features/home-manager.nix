{ self, inputs, ... }: {
  # Standalone Home Manager configuration for the "pops" user.
  # Deliberately NOT wired into the NixOS configuration as a module.
  flake.homeConfigurations.pops = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      self.homeModules.pops
    ];
  };

  # Reusable home module importing the existing home/*.nix entrypoint.
  flake.homeModules.pops = { pkgs, ... }: {
    imports = [ ../../home/default.nix ];
  };
}
