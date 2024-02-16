{ pkgs, username, homeDirectory, ... }: {

  home = {
    stateVersion = "23.05";
    inherit username;
    inherit homeDirectory;
  };

  programs.bash = {
    enable = true;
    bashrcExtra = ''
      . ~/oldbashrc
    '';
  };
}
