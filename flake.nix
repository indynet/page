{
  description = "page";

  inputs      = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs     = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs   = import nixpkgs { inherit system; };
    in
      with builtins;
      with pkgs.lib;
      with pkgs;
    rec {
      mk = { static ? []
           , inputs ? []
           , pages  ? {}
           , page
           , name
           , src
           }:
             let
               toCp = drv: { copy = drv; name = drv.name; };
               copy = to: ls:
                 let
                   f = map ({ copy, name }: "cp -r ${copy} ${to}/${name}") ls;
                   g = concatStringsSep "\n" f;
                 in g;
               make = { static ? []
                      , inputs ? []
                      , pages  ? {}
                      , name
                      , page
                      , meta
                      }:
                        let
                          pages'    =
                            let
                              m = {
                                path = "${meta.last.path}/${meta.name}";
                                name = name;
                                last = meta;
                              };

                              f = x: make (pages.${x} // { name = x; meta = m; });
                              g = attrNames pages;
                            in map f g;
                        in stdenv.mkDerivation {
                          inherit name;
                          inherit src;

                          buildInputs  = inputs ++ pages';
                          buildPhase   = ''
                              runHook preBuild
                              echo "${page meta}" > index.html
                              runHook postBuild
                          '';

                          installPhase = ''
                              runHook preInstall
                              mkdir -p $out/static
                              ${copy "$out/static" static}
                              ${copy "$out"        (map toCp inputs)}
                              ${copy "$out"        (map toCp pages')}
                              cp index.html $out
                              runHook postInstall
                          '';
                        };

               meta = {
                 inherit name;
                 last = meta;
                 path = "/";
               };
             in make {
               inherit static inputs pages page name meta;
             };
    };
}
