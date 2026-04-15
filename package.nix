{ lib
, stdenv
, fetchurl
, installShellFiles
}:

let
  version = "18.15.0";

  targetTriple = {
    "aarch64-darwin" = "aarch64-apple-darwin";
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
  }.${stdenv.hostPlatform.system}
    or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  platformSources = {
    "aarch64-darwin" = fetchurl {
      url = "https://github.com/atuinsh/atuin/releases/download/v${version}/atuin-aarch64-apple-darwin.tar.gz";
      sha256 = "1hxxwc2rdl9gnr83pzinxvh4jibd9jywh16yv3lsx7cnsy6wyrm0";
    };
    "x86_64-linux" = fetchurl {
      url = "https://github.com/atuinsh/atuin/releases/download/v${version}/atuin-x86_64-unknown-linux-musl.tar.gz";
      sha256 = "0n3hh6v4p6y9dby45163mgz1j7sqxlq2zx6whxcsi3gg4kjhpkw3";
    };
    "aarch64-linux" = fetchurl {
      url = "https://github.com/atuinsh/atuin/releases/download/v${version}/atuin-aarch64-unknown-linux-musl.tar.gz";
      sha256 = "03hndayar9313fl5l7cv88dh6j6i94iqsh826874sxq5q62bjhmj";
    };
  };

  platformSrc = platformSources.${stdenv.hostPlatform.system};
in

stdenv.mkDerivation {
  pname = "atuin";
  inherit version;

  src = platformSrc;

  sourceRoot = "atuin-${targetTriple}";

  nativeBuildInputs = [ installShellFiles ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp atuin $out/bin/atuin
    chmod +x $out/bin/atuin
    runHook postInstall
  '';

  postInstall = ''
    $out/bin/atuin gen-completions -s bash > atuin.bash
    $out/bin/atuin gen-completions -s zsh > atuin.zsh
    $out/bin/atuin gen-completions -s fish > atuin.fish
    installShellCompletion --cmd atuin \
      --bash atuin.bash \
      --zsh atuin.zsh \
      --fish atuin.fish
  '';

  meta = with lib; {
    description = "Atuin - magical shell history";
    homepage = "https://github.com/atuinsh/atuin";
    license = licenses.mit;
    platforms = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
    mainProgram = "atuin";
  };
}
