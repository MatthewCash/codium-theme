{
    description = "Theme for VSCodium";

    inputs = {
        nixpkgs.url = "nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
            defaultPackage = pkgs.lib.makeOverridable ({ accentColor }: pkgs.stdenvNoCC.mkDerivation {
                name = "codium-theme";
                vscodeExtUniqueId = "codium-theme";
                vscodeExtPublisher = "Matthew_Cash";
                version = "1.0.0";
                src = ./.;
                nativeBuildInputs = with pkgs; [ nodePackages.npm ];
                dontConfigure = true;
                unpackPhase = ''
                    cp -r $src/{package.json,LICENSE,themes} .
                '';
                patchPhase = let
                    accentColorDark = accentColor // { l = accentColor.l - 5; };
                    accentColorDarker = accentColor // { l = accentColor.l - 10; };

                    toHexDigit = i: import ./util/padStart.nix pkgs.lib {
                        padStr = "0";
                        len = 2;
                        str = import ./util/decToHex.nix pkgs.lib i;
                    };
                    getHex = rgb: "#${toHexDigit rgb.r}${toHexDigit rgb.g}${toHexDigit rgb.b}";
                    getHexFromHsl = hsl: getHex (import ./util/hsl2rgb.nix pkgs.lib hsl);
                in ''
                    substituteInPlace themes/color-theme.json \
                        --replace "{{ACCENTCOLOR}}" "${getHexFromHsl accentColor}" \
                        --replace "{{ACCENTCOLOR_DARK}}" "${getHexFromHsl accentColorDark}" \
                        --replace "{{ACCENTCOLOR_DARKER}}" "${getHexFromHsl accentColorDarker}"
                '';
                buildPhase = ''
                    ${pkgs.vsce}/bin/vsce package -o extension.vsix
                '';
                installPhase = ''
                    outdir="$out/share/vscode/extensions/codium-theme"
                    outdirpacked="$out/share/vscode/extensions"
                    mkdir -p "$outdir" "$outdirpacked"
                    mv extension.vsix "$outdirpacked"
                    cp -r . "$outdir"
                '';
            }) { accentColor = { h = 300; s = 60; l = 70; }; };
        }
    );
}
