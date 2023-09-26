{
  description = "Simple scripts for popping up language translations.";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { nixpkgs, flake-utils, ... }:
    let
      pname = "translation-popup";
      version = "0.0.3";

      overlay = final: prev: {
        translation-popup =
          let
            inherit (prev) makeWrapper symlinkJoin writeScriptBin;
            script = builtins.readFile ./lib/translation-popup.sh;
            buildInputs = with final; [
              bash
              bc
              coreutils
              flameshot
              kitty
              imagemagick
              mpv
              tesseract
              translate-shell
              xclip
            ];
            drv = (writeScriptBin pname script).overrideAttrs(old: {
              buildCommand = "${old.buildCommand}\n patchShebangs $out";
            });
          in symlinkJoin {
            name = "${pname}-${version}";
            paths = [ drv ] ++ buildInputs;
            buildInputs = [ makeWrapper ];
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
    in
    { inherit overlay; } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [overlay]; };
      in rec {
        packages = {
          default = pkgs.translation-popup;
          translation-popup = pkgs.translation-popup;
        };
        devShell = pkgs.mkShell {
          buildInputs = packages.default.paths;
        };
      }
    );
}
