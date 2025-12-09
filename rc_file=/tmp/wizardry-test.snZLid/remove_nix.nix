{ config, pkgs, ... }:

{

  programs.bash.initExtra = ''
source "/path/to/spell" # wizardry: nixremove
  '';
}
