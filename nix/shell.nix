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
    install -Dm644 ${../skull.txt} $out/share/breakland-shell/skull.txt

    cat > $out/bin/breakland-shell <<EOF
    #!${stdenvNoCC.shell}
    if [ "\$1" = "--lock" ]; then
      shift
      exec ${quickshell}/bin/quickshell ipc call breakland lock "\$@"
    fi
    exec ${quickshell}/bin/quickshell -p $out/share/breakland-shell "\$@"
    EOF
    chmod 755 $out/bin/breakland-shell
  '';

  meta = {
    description = "Quickshell desktop shell for BreakLand";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "breakland-shell";
  };
}
