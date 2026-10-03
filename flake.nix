{
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
		flake-utils = {
			url = "github:numtide/flake-utils";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		esp-rs-nix = {
			url = "github:leighleighleigh/esp-rs-nix";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { self, nixpkgs, flake-utils, esp-rs-nix }:
		flake-utils.lib.eachDefaultSystem(system:
			let
				pkgs = import nixpkgs { inherit system; };
				espToolchain = esp-rs-nix.packages.${system}.esp-rs;
				cargo-esp = pkgs.writeShellApplication {
					name = "cargo-esp";
					runtimeInputs = with pkgs; [ coreutils ldproxy espflash ];
					text = ''
						if [ "$#" -gt 0 ] && [ "$1" = esp ]; then
							# Cargo runs plugins as `cargo-esp esp <args>`.
							shift
						fi
						if [ "$#" -eq 0 ]; then
							echo "usage: cargo esp <cargo-command> [args...]" >&2
							exit 1
						fi
						cmd="$1"
						shift
						case "$cmd" in
							-h | --help | help | -V | --version)
								exec "${espToolchain}/bin/cargo" "$cmd" "$@"
								;;
							new | init)
								export PATH="${espToolchain}/bin:$PATH"
								exec "${espToolchain}/bin/cargo" "$cmd" "$@"
								;;
						esac
						export PATH="${espToolchain}/bin:$PATH"
						exec "${espToolchain}/bin/cargo" "$cmd" --target xtensa-esp32s3-none-elf -Z build-std=core,alloc "$@"
					'';
				};
			in {
				packages = {
					inherit cargo-esp;
					default = cargo-esp;
				};
			}
	);
}
