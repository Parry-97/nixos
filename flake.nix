{
  description = "System NixOS Flake configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
  # outputs =
  #   {
  #     self,
  #     nixpkgs,
  #     home-manager,
  #     ...
  #   }@inputs:
  #   {
  #     nixosConfigurations = {
  #       # Matches your networking.hostName = "nixos"
  #       nixos = nixpkgs.lib.nixosSystem {
  #         system = "x86_64-linux";
  #         modules = [
  #           ./hardware-configuration.nix
  #           ./configuration.nix
  #         ];
  #       };
  #     };
  #     # Standalone User builds (Home Manager only)
  #     homeConfigurations = {
  #       "pops" = home-manager.lib.homeManagerConfiguration {
  #         pkgs = nixpkgs.legacyPackages."x86_64-linux";
  #         modules = [ ./home ]; # Points directly to home/default.nix
  #       };
  #     };
  #   };
}
