{
  description = "Location Alarm";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };

      androidComposition = pkgs.androidenv.composeAndroidPackages {
        platformVersions = [ "35" ];
        buildToolsVersions = [ "35.0.0" ];
        includeEmulator = false;
        includeNDK = false;
        includeSources = false;
        includeSystemImages = false;
      };

      androidSdk = androidComposition.androidsdk;
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          androidSdk
          dart
          flutter
          gradle
          jdk21
        ];

        ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
        GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/35.0.0/aapt2";
        JAVA_HOME = "${pkgs.jdk21}";

        shellHook = ''
          echo "Location Alarm dev shell"
        '';
      };
    };
}
