{ nix-darwin, nixpkgs, home-manager, rev, machines, ... }:
with builtins; 
let

  mahcinMapping = listToAttrs (mapAttrs (m: {name="${m.name}@${m.hostname}"; value=m;}) machines)
  ;
  darwinconfiguration = { pkgs, system, modulespath, ... }: {
    system.stateversion = 4;
    system.configurationrevision = rev;
    imports = [
      (modulespath + "/nix/nix-darwin.nix")
    ];
    # auto upgrade nix package and the daemon service.
    nix = {
      settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
      settings.trusted-users = builtins.mapAttrs (m: m.name) machines;

      registry.nixpkgs.to = { type = "path"; path = "${pkgs.path}"; };
      settings.experimental-features = "nix-command flakes";
      package = pkgs.nix;
      envvars =
        if (system == "aarch64-darwin") then {
          http_proxy = "http://127.0.0.1:7890";
          https_proxy = "http://127.0.0.1:7890";
          all_proxy = "socks5://127.0.0.1:7890";
        } else { };
    };
    environment = {
      systempackages = with pkgs; [
        vim
        git
      ];
      variables = {
      };
    };


    services = {
      nix-daemon.enable = true;
    };

    homebrew = {
      enable = true;
      taps = [
        "homebrew/bundle"
        "homebrew/cask-versions"
      ];
      masapps = {
      };
      brews = [
        "wget"
        "gnupg"
      ];
      casks = [
      ];
      extraconfig = "";
    };


    # the platform the configuration will be used on.
    nixpkgs.hostplatform = system;

  };

  # 为每个用户或主机生成对应的配置
  createdarwinsystem = { userconfig, ... }: nix-darwin.lib.darwinsystem {
    #
    inherit (userconfig) system;
    modules = [
      darwinconfiguration
      home-manager.darwinmodules.home-manager

      # per host configration
      {
        users.users = {
          ${userconfig.name} = {
            name= userconfig.name;
            home =  userconfig.home;
          };
        };

        home-manager.useglobalpkgs = true;
        home-manager.useuserpackages = true;
        home-manager.users.${userconfig.name} = import ./home.nix;
        home-manager.extraspecialargs = {
          #pkgs = (nixpkgs.legacypackages.${userconfig.system}.extend (import ./overlays/default.nix));
          pkgs = (nixpkgs.legacypackages.${userconfig.system});
          inherit (userconfig) username;
          inherit (userconfig) homeDirectory;
        };
      }
    ];
    specialargs = { inherit (userconfig) system; };
  };
in
 genAttrs (attrNames mahcinMapping) (hostStr:
createdarwinsystem {
    userconfig = mahcinMapping.${hostStr};
  })
