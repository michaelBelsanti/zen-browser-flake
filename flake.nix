{
  description = "Zen Browser";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      version = "1.0.0-a.27";
      downloadUrl = {
        "specific" = {
	  url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-specific.tar.bz2";
	  sha256 = "sha256:0vmn10qpr96b4i8j24sa6ipg3fcxiiigkjwclbr5fknkfj3r6ds7";
	};
	"generic" = {
	  url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-generic.tar.bz2";
	  sha256 = "sha256:1801pcvvmmdz5drqvxs95yzij099mhq7cnw663dna4kcn2nqwvni";
	};
      };

      pkgs = import nixpkgs {
        inherit system;
      };

      runtimeLibs = with pkgs; [
        libGL stdenv.cc.cc fontconfig libxkbcommon zlib freetype
        gtk3 libxml2 dbus xcb-util-cursor alsa-lib pango atk cairo gdk-pixbuf glib
      ] ++ (with pkgs.xorg; [
        libxcb libX11 libXcursor libXrandr libXi libXext libXcomposite libXdamage libXfixes
      ]);

      mkZen = { variant }: 
        let
	  downloadData = downloadUrl."${variant}";
	in
             pkgs.stdenv.mkDerivation {
		name = "zen-browser";

		src = builtins.fetchTarball {
		  url = downloadData.url;
		  sha256 = downloadData.sha256;
		};
		
		desktopSrc = ./.;

		phases = [ "installPhase" "fixupPhase" ];

		nativeBuildInputs = [ pkgs.makeWrapper pkgs.copyDesktopItems pkgs.wrapGAppsHook ] ;

		installPhase = ''
		  mkdir -p $out/bin && cp -r $src/* $out/bin
		  install -D $desktopSrc/zen.desktop $out/share/applications/dev.zen.Zen.desktop
		  install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png
		'';

		fixupPhase = ''
		  chmod 755 $out/bin/*
		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen
		  wrapProgram $out/bin/zen --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen-bin
		  wrapProgram $out/bin/zen-bin --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/glxtest
		  wrapProgram $out/bin/glxtest --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/updater
		  wrapProgram $out/bin/updater --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/vaapitest
		  wrapProgram $out/bin/vaapitest --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
		'';

    meta.mainProgram = "zen";
	      };
    in
    {
      packages."${system}" = {
        generic = mkZen { variant = "generic"; };
        specific = mkZen { variant = "specific"; };
	default = self.packages."${system}".specific;
      };
    };
}
