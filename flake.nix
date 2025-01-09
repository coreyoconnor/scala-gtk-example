{
  description = "scala-gtk-example";

  inputs = {
    flake-utils.follows = "typelevel-nix/flake-utils";
    nixpkgs.follows = "typelevel-nix/nixpkgs";
    sbt = {
      url = "github:zaninime/sbt-derivation/master";
      inputs.nixpkgs.follows = "typelevel-nix/nixpkgs";
    };
    typelevel-nix.url = "github:typelevel/typelevel-nix";
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    sbt,
    typelevel-nix
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ typelevel-nix.overlays.default ];
        };
        nativeBuildInputs = with pkgs; [
          pkg-config
          which
          glib.dev
        ];
        buildInputs = with pkgs; [
          boehmgc
          cairo
          gdk-pixbuf
          graphene
          harfbuzz
          libunwind
          glib
          gtk4
          pango
          vulkan-headers
          vulkan-loader
          zlib
        ];
      in
      rec {
        packages = {
          default = (sbt.mkSbtDerivation.${system}).withOverrides({ stdenv = pkgs.llvmPackages_15.stdenv; }) {
            pname = "scala-gtk-example";
            version = "0.1.0";
            src = self;
            depsSha256 = "sha256-Xl7W02/ouDMXTS26qKgUPD9wsCWMCyEneu4nQ6grjd8=";
            buildPhase = ''
              sbt compile
            '';
            depsWarmupCommand = ''
              sbt '+Test/updateFull ; +Test/compileIncSetup'
            '';
            installPhase = ''
              sbt 'show stage'
              mkdir -p $out/bin
              cp target/scala-gtk-example $out/bin/
            '';
            inherit buildInputs nativeBuildInputs;
            env.NIX_CFLAGS_COMPILE = "-Wno-unused-command-line-argument";
            hardeningDisable = [ "fortify" ];
          };
        };

        devShell = pkgs.devshell.mkShell {
          imports = [ typelevel-nix.typelevelShell "${pkgs.devshell.extraModulesDir}/language/c.nix"];
          name = "scalatromino-devshell";
          typelevelShell = {
            jdk.package = pkgs.jdk21;
            native.enable = true;
          };
          packagesFrom = [ packages.default ];
          language.c = {
            libraries = buildInputs;
            includes = buildInputs;
          };
        };
    });
}
