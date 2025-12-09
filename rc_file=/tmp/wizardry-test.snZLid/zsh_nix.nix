{ config, pkgs, ... }:

{

  programs.zsh.initExtra = ''
source "/path/to/spell" # wizardry: zshspell
  '';
}
