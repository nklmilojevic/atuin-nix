{ lib
, stdenv
, fetchurl
, installShellFiles
}:

let
  version = "18.14.0";

  targetTriple = {
    "aarch64-darwin" = "aarch64-apple-darwin";
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
  }.${stdenv.hostPlatform.system}
    or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  platformSources = {
    "aarch64-darwin" = fetchurl {
      url = "https://github.com/atuinsh/atuin/releases/download/v${version}/atuin-aarch64-apple-darwin.tar.gz";
      sha256 = "1sx8aplgy7l4rbia8rdg7jfll9cwl2xcvvrdjkvrkz237kj8lp66";
    };
    "x86_64-linux" = fetchurl {
      url = "https://github.com/atuinsh/atuin/releases/download/v${version}/atuin-x86_64-unknown-linux-musl.tar.gz";
      sha256 = "0d5yzr7ha8464kqn15ahh5kd9lng2ssnr3mlh586wr9jspv46p9g";
    };
    "aarch64-linux" = fetchurl {
      url = "https://github.com/atuinsh/atuin/releases/download/v${version}/atuin-aarch64-unknown-linux-musl.tar.gz";
      sha256 = "05fhalqyq2pz68bnipcjqdly0wfs4z0i6cq0psprb2558a52xlp3";
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
