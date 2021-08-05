with import <nixpkgs> {};
let
  # CoC Config
  cocConfig = writeText "coc-settings.json" (
    builtins.toJSON {
      "python.formatting.provider" = "black";
      "python.linting.enabled" = true;
      "python.linting.flake8Enabled" = true;
      "python.linting.mypyEnabled" = true;
      "python.linting.pylintEnabled" = false;
      "python.pythonPath" = "/home/sumner/projects/beeper/.venv/bin/python";
    }
  );

  projectUris = [
    "git@github.com:sumnerevans/linkedin-matrix.git"
    "git@github.com:sumnerevans/linkedin-messaging-api.git"
    "git@github.com:tulir/mautrix-facebook.git"
    "git@github.com:tulir/mautrix-hangouts.git"
    "git@github.com:tulir/mautrix-instagram.git"
    "git@github.com:tulir/mautrix-python.git"
    "git@github.com:tulir/mautrix-signal.git"
    "git@github.com:tulir/mautrix-telegram.git"
    "git@github.com:tulir/mautrix-twitter.git"
    "git@gitlab.com:beeper/beeper-desktop.git"
    "git@gitlab.com:beeper/beeper-services.git"
    "git@gitlab.com:beeper/libsignal-service-java.git"
    "git@gitlab.com:beeper/signald.git"
  ];

  initGitPkgs = let
    cloneCmd = uri: ''
      IFS='/' read -ra parts <<< "${uri}"
      dir="''${parts[-1]}"
      if [[ $dir =~ ^.*.git$ ]]; then
        dir=''${dir::-4}
      fi

      if [[ -d $dir ]]; then
        echo "$dir already exists. Will not create."
      else
        ${pkgs.git}/bin/git clone --recurse-submodules -j8 ${uri} $dir
      fi
    '';
  in
    pkgs.writeShellScriptBin "initgit" ''
      echo
      echo Cloning necessary repos
      echo
      ${lib.concatMapStringsSep "\n" cloneCmd projectUris}
      echo
    '';
in
mkShell rec {
  name = "impurePythonEnv";
  venvDir = "./.venv";

  buildInputs = [
    python3
    python3Packages.venvShellHook

    # Python Dependencies
    python3Packages.psycopg2
    python3Packages.python-olm
    python3Packages.python_magic

    initGitPkgs

    rnix-lsp
  ];

  # Run this command, only after creating the virtual environment
  postVenvCreation = ''
    unset SOURCE_DATE_EPOCH
  '';

  # Now we can execute any commands within the virtual environment.
  # This is optional and can be left out to run pip manually.
  postShellHook = ''
    # allow pip to install wheels
    unset SOURCE_DATE_EPOCH

    mkdir -p .vim
    ln -sf ${cocConfig} .vim/coc-settings.json
  '';
}
