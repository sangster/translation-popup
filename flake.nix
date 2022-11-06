{
  description = "Simple scripts for popping up language translations.";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        pname = "translation-popup";
        version = "0.0.1";

        script = builtins.readFile ./lib/translation-popup.sh;
        buildInputs = with pkgs; [
          coreutils
          flameshot
          kitty
          mpv
          tesseract
          translate-shell
          xclip
        ];

        drv = (pkgs.writeScriptBin pname script).overrideAttrs(old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });
      in rec {
        packages = {
          default = packages.translate-shell;

          translate-shell = pkgs.symlinkJoin {
            name = "${pname}-${version}";
            paths = [ drv ] ++ buildInputs;
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/${pname} \
                --inherit-argv0 \
                --prefix PATH : $out/bin
            '';
            passthru = {
              inherit version;
            };
          };
        };
      }
    );
}
