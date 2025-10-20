{
  description = "Contributor environment for Nix-based BEAM toolchain management";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    pre-commit = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin" "x86_64-darwin" "x86_64-linux"];

      imports = [./checksums inputs.pre-commit.flakeModule];

      perSystem = {
        config,
        lib,
        pkgs,
        system,
        ...
      }: {
        devShells.default = pkgs.mkShell {
          buildInputs =
            [pkgs.just]
            ++ (with inputs.pre-commit.packages.${system};
              [alejandra pre-commit]
              ++ lib.optionals pkgs.stdenv.isLinux [statix]);
          shellHook = config.pre-commit.installationScript;
        };

        formatter = pkgs.alejandra;

        packages.gcroot =
          pkgs.linkFarmFromDrvs "beam-overlay-dev"
          [config.devShells.default.inputDerivation];

        pre-commit = {
          settings = {
            hooks = {
              alejandra.enable = true;
              deadnix.enable = true;
              prettier.enable = true;
              prettier.excludes = ["flake.lock"];
              statix = {
                enable = pkgs.stdenv.isLinux;
                settings = {
                  ignore = [".direnv/*"];
                };
              };
            };
            rootSrc = lib.mkForce ./..;
          };
        };
      };
    };
}
