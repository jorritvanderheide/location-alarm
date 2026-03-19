{ ... }:
{
  projectRootFile = "flake.nix";
  programs.nixfmt.enable = true;
  programs.dart-format.enable = true;
  programs.yamlfmt.enable = true;

  settings.formatter.yamlfmt.excludes = [
    "pubspec.yaml"
    "pubspec.lock"
  ];
}
