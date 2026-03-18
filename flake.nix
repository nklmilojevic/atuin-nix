{
  description = "Nix flake for Atuin - magical shell history";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      overlay = final: prev: {
        atuin = final.callPackage ./package.nix { };
      };
    in
    flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        packages = {
          default = pkgs.atuin;
          atuin = pkgs.atuin;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.atuin}/bin/atuin";
          };
          atuin = {
            type = "app";
            program = "${pkgs.atuin}/bin/atuin";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixpkgs-fmt
            nix-prefetch-git
            cachix
          ];
        };
      }) // {
        overlays.default = overlay;
      };
}
