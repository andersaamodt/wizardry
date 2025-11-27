{
  description = "Wizardry - the terminal's missing link";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Create a derivation that installs wizardry
        wizardry = pkgs.stdenvNoCC.mkDerivation {
          pname = "wizardry";
          version = "0.1.0";
          
          src = ./.;
          
          # No build phase needed - wizardry is shell scripts
          dontBuild = true;
          
          installPhase = ''
            runHook preInstall
            
            # Create the output directory
            mkdir -p $out/share/wizardry
            mkdir -p $out/bin
            
            # Copy all files
            cp -r spells $out/share/wizardry/
            cp -r tests $out/share/wizardry/
            cp -r tutorials $out/share/wizardry/ 2>/dev/null || true
            cp install $out/share/wizardry/
            cp README.md $out/share/wizardry/
            
            # Create wrapper scripts for main commands
            # The menu command
            cat > $out/bin/menu <<EOF
#!/bin/sh
exec "$out/share/wizardry/spells/menu/menu" "\$@"
EOF
            chmod +x $out/bin/menu
            
            # The mud command
            cat > $out/bin/mud <<EOF
#!/bin/sh
exec "$out/share/wizardry/spells/mud/mud" "\$@"
EOF
            chmod +x $out/bin/mud
            
            # Create a setup script that adds all spell directories to PATH
            cat > $out/share/wizardry/setup.sh <<EOF
# Wizardry setup script - source this to add spells to PATH
# Usage: . /path/to/wizardry/setup.sh

WIZARDRY_ROOT="$out/share/wizardry"
export WIZARDRY_ROOT

# Add all spell directories to PATH
EOF
            
            # Recursively find all directories under spells and add to setup.sh
            find $out/share/wizardry/spells -type d | while read -r dir; do
              echo "export PATH=\"\$PATH:$dir\"" >> $out/share/wizardry/setup.sh
            done
            
            runHook postInstall
          '';
          
          meta = {
            description = "Wizardry - a collection of shell scripts to complete your terminal experience";
            homepage = "https://github.com/andersaamodt/wizardry";
            license = pkgs.lib.licenses.mit;
            platforms = pkgs.lib.platforms.unix;
            maintainers = [];
          };
        };
      in
      {
        packages = {
          default = wizardry;
          wizardry = wizardry;
        };
        
        # Development shell with wizardry available
        devShells.default = pkgs.mkShell {
          packages = [ wizardry ];
          shellHook = ''
            export WIZARDRY_ROOT="${wizardry}/share/wizardry"
            source "${wizardry}/share/wizardry/setup.sh"
            echo "Wizardry is ready! Type 'menu' or 'mud' to start."
          '';
        };
      }
    ) // {
      # Home-manager module
      homeManagerModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.wizardry;
        in
        {
          options.programs.wizardry = {
            enable = lib.mkEnableOption "wizardry shell scripts";
            
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.system}.wizardry;
              defaultText = lib.literalExpression "pkgs.wizardry";
              description = "The wizardry package to use.";
            };
          };
          
          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];
            
            # Add spell directories to PATH via session variables
            home.sessionVariables = {
              WIZARDRY_ROOT = "${cfg.package}/share/wizardry";
            };
            
            # Source the setup script in bash/zsh
            programs.bash.initExtra = lib.mkIf config.programs.bash.enable ''
              # Wizardry setup
              source "${cfg.package}/share/wizardry/setup.sh"
            '';
            
            programs.zsh.initExtra = lib.mkIf config.programs.zsh.enable ''
              # Wizardry setup
              source "${cfg.package}/share/wizardry/setup.sh"
            '';
          };
        };
      
      # NixOS module (for system-wide installation)
      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.wizardry;
        in
        {
          options.programs.wizardry = {
            enable = lib.mkEnableOption "wizardry shell scripts";
            
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.system}.wizardry;
              defaultText = lib.literalExpression "pkgs.wizardry";
              description = "The wizardry package to use.";
            };
          };
          
          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];
            
            # Add to environment variables
            environment.sessionVariables = {
              WIZARDRY_ROOT = "${cfg.package}/share/wizardry";
            };
            
            # Add all spell directories to PATH
            environment.shellInit = ''
              # Wizardry setup
              source "${cfg.package}/share/wizardry/setup.sh"
            '';
          };
        };
    };
}
