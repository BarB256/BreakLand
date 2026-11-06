{
  lib,
  stdenvNoCC,
  quickshell,
  makeWrapper,
}:
stdenvNoCC.mkDerivation {
  pname = "breakland-shell";
  version = "0.1.0";
  src = ../shell;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/share/breakland-shell
    cp shell.qml $out/share/breakland-shell/shell.qml

    makeWrapper ${quickshell}/bin/quickshell $out/bin/breakland-shell \
      --add-flags "-p $out/share/breakland-shell"
  '';

  meta = {
    description = "Quickshell desktop shell for BreakLand";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "breakland-shell";
  };
}
