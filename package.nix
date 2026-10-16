{ lib
, stdenv
, fetchurl
, installShellFiles
}:

let
  version = "18.24.0";

  targetTriple = {
    "aarch64-darwin" = "aarch64-apple-darwin";
    "x86_64-linux" = "x86_64-unknown-linux-musl";
    "aarch64-linux" = "aarch64-unknown-linux-musl";
  }.${stdenv.hostPlatform.system}
    or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  platformSources = {
    "aarch64-darwin" = fetchurl {
      url = "https://github.com/atuinsh/atuin/releases/download/v${version}/atuin-aarch64-apple-darwin.tar.gz";
      sha256 = "1cckbq4s4xc1jfd1mjf73sxqvkjqlqsc3jkh7qa0l7lr23ms81a7";
    };
    "x86_64-linux" = fetchurl {
      url = "https://github.com/atuinsh/atuin/releases/download/v${version}/atuin-x86_64-unknown-linux-musl.tar.gz";
      sha256 = "0d34mdk1ff65k8myb08nh4kz1zbda9rp6zrsj6m0db3m1nnvkdji";
    };
    "aarch64-linux" = fetchurl {
      url = "https://github.com/atuinsh/atuin/releases/download/v${version}/atuin-aarch64-unknown-linux-musl.tar.gz";
      sha256 = "0hskml437b532cfhbpmc3daykh18pnq8bqn6qix06bncdj9ns2mw";
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
