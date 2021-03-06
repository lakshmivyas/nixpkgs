{ lib
, crossSystem, config
, bootStages
, ...
}:

assert crossSystem == null;

bootStages ++ [
  (prevStage: let
    inherit (prevStage) stdenv;
  in {
    inherit (prevStage) buildPlatform hostPlatform targetPlatform;
    inherit config overlays;

    stdenv = import ../generic rec {
      inherit config;

      preHook = ''
        export NIX_ENFORCE_PURITY="''${NIX_ENFORCE_PURITY-1}"
        export NIX_ENFORCE_NO_NATIVE="''${NIX_ENFORCE_NO_NATIVE-1}"
        export NIX_IGNORE_LD_THROUGH_GCC=1
      '';

      initialPath = (import ../common-path.nix) { pkgs = prevStage; };

      system = stdenv.system;

      cc = import ../../build-support/cc-wrapper {
        nativeTools = false;
        nativePrefix = stdenv.lib.optionalString stdenv.isSunOS "/usr";
        nativeLibc = true;
        inherit stdenv;
        inherit (prevStage) binutils coreutils gnugrep;
        cc = prevStage.gcc.cc;
        isGNU = true;
        shell = prevStage.bash + "/bin/sh";
      };

      shell = prevStage.bash + "/bin/sh";

      fetchurlBoot = stdenv.fetchurlBoot;

      overrides = self: super: {
        inherit cc;
        inherit (cc) binutils;
        inherit (prevStage)
          gzip bzip2 xz bash coreutils diffutils findutils gawk
          gnumake gnused gnutar gnugrep gnupatch perl;
      };
    };
  })
]
