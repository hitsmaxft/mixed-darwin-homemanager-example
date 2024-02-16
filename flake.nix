{
  description = "flake: home-manager configuration works both for darwin module or standalone";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-23.11-darwin";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ self
    , nix-darwin
    , nixpkgs
    , home-manager
    , flake-utils
    , ...
    }:
    let
      systems = [ "x86_64-darwin" ];
      users = [ "user1" "user2" ];

      formatters = flake-utils.lib.eachSystem systems (system: {
        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
      });

      homePackages = flake-utils.lib.eachSystem systems (system:

        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {

          packages.homeConfigurations = nixpkgs.lib.genAttrs users (name: home-manager.lib.homeManagerConfiguration {
            #pkgs = (nixpkgs.legacyPackages.${system}.extend (import ./overlays/default.nix));
            inherit pkgs;
            # Specify your home configuration modules here, for example,
            # the path to your home.nix.
            modules = [ ./home.nix ];
            # Optionally use extraSpecialArgs
            # to pass through arguments to home.nix

            extraSpecialArgs = {
              #arguments pass into home-configuration.nix
              username = name;
              homeDirectory = "/home/${name}";
            };
          });
        });
    in
    {
      inherit (formatters) formatter;
      inherit (homePackages) packages;
    };
}
