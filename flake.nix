{
  description = "flake: home-manager configuration works both for darwin module or standalone";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-23.11-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
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
      rev = self.rev or self.dirtyRev or null;
      machines = [
        ## mbp 16 2019 intel
        {
          home = "/Users/user1";
          name = "user1";
          system = "x86_64-darwin";
          hostname = "host1";
        }
      ];

      machineMapping = 
        builtins.listToAttrs (builtins.map (m: {name="${m.name}@${m.hostname}"; value=m;}) machines);

      machineNames = builtins.attrNames machineMapping;

      systems = map (m: m.system) machines;

      formatters = flake-utils.lib.eachSystem systems (system: {
        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
      });

      homePackages = flake-utils.lib.eachSystem systems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # username@hostname
        in
        {
          packages.homeConfigurations = nixpkgs.lib.genAttrs (machineNames) (
            hoststr: builtins.trace (builtins.attrNames machineMapping) home-manager.lib.homeManagerConfiguration 
            {
            #pkgs = (nixpkgs.legacyPackages.${system}.extend (import ./overlays/default.nix));
            inherit pkgs;
            # Specify your home configuration modules here, for example,
            # the path to your home.nix.
            modules = [ ./home.nix ];
            # Optionally use extraSpecialArgs
            # to pass through arguments to home.nix

            extraSpecialArgs = {
              #arguments pass into home-configuration.nix
              username = machineMapping.${hoststr}.name;
              homeDirectory = machineMapping.${hoststr}.home;
            };
          });
        });

    in
    {
      inherit (formatters) formatter;
      inherit (homePackages) packages;

      darwinConfigurations = (import ./darwin.nix {
        inherit nixpkgs;
        inherit home-manager;
        inherit nix-darwin;
        inherit machines;
        inherit rev;
      });
    };
}
