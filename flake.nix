{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pname = "sdlreader";
        version = "0.1.0";
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          inherit pname version;
          src = ./.;

          # Tools needed at build time
          nativeBuildInputs = [
            pkgs.pkg-config
          ];

          # Libraries required to compile and link
          buildInputs = [
            pkgs.SDL2
            pkgs.SDL2_ttf
            pkgs.mupdf
          ];

          # Pass flags to Makefile to use Nix-provided tools/paths
          makeFlags = [
            # Use Nix-provided C++ compiler
            "CXX=${pkgs.stdenv.cc}/bin/c++"
          ];

          # Patch Makefile to use Nix MuPDF paths and correct libs
          postPatch = ''
            substituteInPlace Makefile \
              --replace 'MUPDF_OPT_PATH = /usr/local/opt/mupdf-tools' 'MUPDF_OPT_PATH = ${pkgs.mupdf.dev}' \
              --replace '-L$(MUPDF_OPT_PATH)/lib' '-L${pkgs.mupdf}/lib' \
              --replace '-lmupdf -lmupdf-third' '-lmupdf';
          '';

          # Use the default buildPhase (make) so makeFlags are applied

          installPhase = ''
            mkdir -p $out/bin
            cp -v bin/sdl_reader_cli $out/bin/
          '';

          meta = with pkgs.lib; {
            description = "SDL2-based PDF viewer (CLI) using MuPDF";
            license = licenses.mit;
            platforms = platforms.unix;
            mainProgram = "sdl_reader_cli";
          };
        };

        # nix run .# will run the CLI
        apps.default = {
          type = "app";
          program = "${pkgs.lib.getExe self.packages.${system}.default}";
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.pkg-config
            pkgs.SDL2
            pkgs.SDL2_ttf
            pkgs.mupdf
            pkgs.gnumake
          ];
        };
      }
    );
}