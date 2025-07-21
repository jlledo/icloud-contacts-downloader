{
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      uv2nix,
      pyproject-nix,
      pyproject-build-systems,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        inherit (nixpkgs) lib;

        workspace = uv2nix.lib.workspace.loadWorkspace {
          workspaceRoot = ./.;
        };

        overlay = workspace.mkPyprojectOverlay {
          sourcePreference = "wheel";
        };

        pkgs = import nixpkgs { inherit system; };

        python = pkgs.python313;

        pythonSet =
          (pkgs.callPackage pyproject-nix.build.packages {
            inherit python;
          }).overrideScope
            (
              lib.composeManyExtensions [
                pyproject-build-systems.overlays.default
                overlay
              ]
            );

      in
      {
        packages.default =
          let
            addMeta =
              drv:
              drv.overrideAttrs (old: {
                meta = (old.meta or { }) // {
                  mainProgram = "icloudcd";
                };
              });
          in
          addMeta (pythonSet.mkVirtualEnv "icloudcd-env" workspace.deps.default);

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/icloudcd";
        };

        devShells.default =
          let
            editableOverlay = workspace.mkEditablePyprojectOverlay {
              root = "$REPO_ROOT";
            };

            editablePythonSet = pythonSet.overrideScope (
              lib.composeManyExtensions [
                editableOverlay

                (final: prev: {
                  icloud-contacts-downloader = prev.icloud-contacts-downloader.overrideAttrs (old: {
                    src = lib.fileset.toSource {
                      root = old.src;
                      fileset = lib.fileset.unions [
                        (old.src + "/pyproject.toml")
                        (old.src + "/README.md")
                      ];
                    };

                    nativeBuildInputs =
                      old.nativeBuildInputs
                      ++ final.resolveBuildSystem {
                        editables = [ ];
                      };
                  });

                })
              ]
            );

            virtualenv = editablePythonSet.mkVirtualEnv "icloudcd-dev-env" workspace.deps.all;

          in
          pkgs.mkShell {
            packages = [
              virtualenv
              pkgs.uv
            ];

            env = {
              # Don't create venv using uv
              UV_NO_SYNC = "1";

              # Force uv to use nixpkgs Python interpreter
              UV_PYTHON = python.interpreter;

              # Prevent uv from downloading managed Python's
              UV_PYTHON_DOWNLOADS = "never";
            };

            shellHook = ''
              # Undo dependency propagation by nixpkgs.
              unset PYTHONPATH

              # Get repository root using git. This is expanded at runtime by the editable `.pth` machinery.
              export REPO_ROOT=$(git rev-parse --show-toplevel)
            '';
          };
      }
    );

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
