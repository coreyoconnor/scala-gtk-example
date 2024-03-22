{
  description = "scala-gtk-example";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  inputs.sbt.url = "github:zaninime/sbt-derivation/master";
  inputs.sbt.inputs.nixpkgs.follows = "nixpkgs";

  inputs.systems.url = "github:nix-systems/default";

  outputs = {
    self,
    nixpkgs,
    sbt,
    systems
  }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = eachSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          default = (sbt.mkSbtDerivation.${system}).withOverrides({ stdenv = pkgs.llvmPackages_15.stdenv; }) {
            pname = "scala-gtk-example";
            version = "0.1.0";
            src = self;
            depsSha256 = "sha256-BS7bEtrkJTEj2aJ91L1NAA06W0CKIYlG0v3w7qqgyE8=";
            buildPhase = ''
              sbt compile
            '';
            installPhase = ''
              sbt 'show stage'
              mkdir -p $out/bin
              cp target/scala-gtk-example $out/bin/
            '';
            buildInputs = with pkgs; [
              gtk4
            ];
            nativeBuildInputs = with pkgs; [
              boehmgc
              llvmPackages_15.clang
              libunwind
              pkg-config
              stdenv
              which
              zlib
            ];
            env.NIX_CFLAGS_COMPILE = "-Wno-unused-command-line-argument";
            hardeningDisable = [ "fortify" ];
          };
        }
      );
    };
}
