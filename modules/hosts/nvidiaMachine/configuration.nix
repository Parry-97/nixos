{ self, inputs, ... }: {

  flake.nixosModules.nvidiaMachineConfiguration =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    {
      imports = [
        self.nixosModules.nvidiaMachineHardware
        self.nixosModules.niri
      ];

      # Bootloader.
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          "pops"
        ];

        substituters = [
          "https://cache.nixos-cuda.org"
        ];
        trusted-public-keys = [
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];
      };

      # Use latest kernel.
      boot.kernelPackages = pkgs.linuxPackages_latest;

      networking.hostName = "nixos"; # Define your hostname.
      # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

      # Configure network proxy if necessary
      # networking.proxy.default = "http://user:password@proxy:port/";
      # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

      # Enable networking
      networking.networkmanager.enable = true;

      # Set your time zone.
      time.timeZone = "Europe/Rome";

      # Select internationalisation properties.
      i18n.defaultLocale = "en_US.UTF-8";

      i18n.extraLocaleSettings = {
        LC_ADDRESS = "it_IT.UTF-8";
        LC_IDENTIFICATION = "it_IT.UTF-8";
        LC_MEASUREMENT = "it_IT.UTF-8";
        LC_MONETARY = "it_IT.UTF-8";
        LC_NAME = "it_IT.UTF-8";
        LC_NUMERIC = "it_IT.UTF-8";
        LC_PAPER = "it_IT.UTF-8";
        LC_TELEPHONE = "it_IT.UTF-8";
        LC_TIME = "it_IT.UTF-8";
      };

      # Enable the X11 windowing system.
      services.xserver.enable = true;

      hardware.graphics.enable = true;
      hardware.nvidia-container-toolkit.enable = true;
      virtualisation.docker = {
        # Consider disabling the system wide Docker daemon
        enable = false;

        rootless = {
          enable = true;
          setSocketVariable = true;
          # Optionally customize rootless Docker daemon settings
          daemon.settings = {
            data-root = "${config.users.users."pops".home}/.local/docker";
            dns = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            registry-mirrors = [ "https://mirror.gcr.io" ];
            features.cdi = true;
          };
        };
      };

      # Nvidia Configuration
      services.xserver.videoDrivers = [
        # "modesetting"
        "nvidia"
      ];
      hardware.nvidia = {
        open = false;
        package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
        modesetting.enable = true;
        powerManagement.enable = true;
        prime = {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          intelBusId = "PCI:0@0:2:0";
          nvidiaBusId = "PCI:1@0:0:0";
        };
        # amdgpuBusId = "PCI:5@0:0:0"; # If you have an AMD iGPU
      };

      # Enable the GNOME Desktop Environment.
      services.xserver.displayManager.gdm.enable = true;
      services.xserver.desktopManager.gnome.enable = true;

      # Configure keymap in X11
      services.xserver.xkb = {
        layout = "it";
        variant = "";
      };

      # Configure console keymap
      console.keyMap = "it2";

      # Enable CUPS to print documents.
      services.printing.enable = true;

      # Enable sound with pipewire.
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        # If you want to use JACK applications, uncomment this
        #jack.enable = true;

        # use the example session manager (no others are packaged yet so this is enabled by default,
        # no need to redefine it in your config for now)
        #media-session.enable = true;
      };

      # Enable touchpad support (enabled default in most desktopManager).
      services.xserver.libinput.enable = true;

      # Define a user account. Don't forget to set a password with ‘passwd’.
      users.users."pops" = {
        isNormalUser = true;
        description = "pops";
        linger = true;
        subUidRanges = [
          {
            startUid = 100000;
            count = 65536;
          }
        ];
        subGidRanges = [
          {
            startGid = 100000;
            count = 65536;
          }
        ];
        extraGroups = [
          "networkmanager"
          "wheel"
          "kvm" # required by docker-sbx microVMs
        ];
        packages = with pkgs; [
          #  thunderbird
        ];
      };

      # Install firefox.
      programs.firefox.enable = true;
      programs.starship.enable = true;

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # Pin docker-sbx newer than nixpkgs' locked version. v0.34.0 fails to create
      # sandboxes on current templates ("plugin block not found"); 0.37.0 fixed
      # that but only shipped the intermediate kit-spec v2 grammar. 0.38.0 carries
      # the strict v2 grammar (permissions/setup/agentInstructions) used by our
      # kits. Bump when nixpkgs catches up, then drop this overlay.
      nixpkgs.overlays = [
        (final: prev: {
          docker-sbx = prev.docker-sbx.overrideAttrs (old: {
            version = "0.38.0";
            src = final.fetchurl {
              url = "https://github.com/docker/sbx-releases/releases/download/v0.38.0/DockerSandboxes-linux-amd64.tar.gz";
              hash = "sha256-nrzqgx1NJw4lrhd3vxXiR1ar+/h5GtJylHVGgoOO0As=";
            };
          });
          # NVIDIA + Wayland + Qt6 cannot create EGL contexts (EGL_BAD_MATCH 3009),
          # which breaks rendering and the file picker. Force xcb + GLX (see
          # NixOS/nixpkgs#417301).
          sioyek = prev.sioyek.overrideAttrs (old: {
            qtWrapperArgs = (old.qtWrapperArgs or [ ]) ++ [
              "--set QT_QPA_PLATFORM xcb"
              "--set QT_XCB_GL_INTEGRATION xcb_glx"
            ];
          });
        })
      ];

      # Expose gtk3's gsettings schemas so the GTK3 file chooser used by Qt apps
      # (e.g. sioyek's `o` dialog) can read org.gtk.Settings.FileChooser instead
      # of aborting on a missing schema.
      environment.sessionVariables.XDG_DATA_DIRS = [
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
      ];

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; [
        docker-sbx
        vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
        git
        ghostty
        gh
        nushell
        jq
        tmux
        fastfetch
        brave
        xclip
        pass
        gnupg
        devenv
        opencode
        # gitbutler
        jujutsu
        gnumake
        kubernetes-helm
        dust
        # nh
        nvd
        nix-output-monitor
        tmux
        sioyek
        # fzf
        # zoxide
        eza
        ripgrep
        lazygit
        xh
        starship
        zip
        unzip
        fd
        tuicr
        k9s
        #  wget
        telegram-desktop
        obsidian
      ];

      fonts.packages = with pkgs; [
        # nerd-fonts.jetbrains-mono
        nerd-fonts.symbols-only # Essential for icon rendering
        monaspace
        nunito
        (google-fonts.override { fonts = [ "Spectral" ]; })
      ];

      programs.nix-ld = {
        enable = true;
        # Optional: add extra libraries here if the binary complains about missing .so files
        libraries = with pkgs; [
          dbus # Provides libdbus-1.so.3
          stdenv.cc.cc # Provides libstdc++.so.6 / libgcc_s.so.1
          zlib # Provides libz.so.1
          openssl # Provides libcrypto.so / libssl.so
          glib # Provides libglib-2.0.so
          curl # Provides libcurl.so
        ];
      };

      programs.nh = {
        enable = true;
        flake = "/home/pops/.config/nixos"; # Path to your flake directory
      };

      programs.neovim = {
        enable = true;
        defaultEditor = true;
      };

      # Enable Tailscale
      services.tailscale = {
        # Enable tailscale at startup
        enable = true;

        # If you would like to use a preauthorized key, set
        # authKeyFile = "/run/secrets/tailscale_key";
        # Note: maximum expire time is 90 days
      };

      # Enable emacs
      services.emacs = {
        enable = true;
        # defaultEditor = true;
        # Use emacs-gtk or emacs-pgtk as needed
        package = pkgs.emacs-gtk;
      };

      # Some programs need SUID wrappers, can be configured further or are
      # started in user sessions.
      # programs.mtr.enable = true;
      programs.gnupg.agent = {
        enable = true;
        # enableSSHSupport = true;
      };

      # List services that you want to enable:

      # Enable the OpenSSH daemon.
      # services.openssh.enable = true;

      # Open ports in the firewall.
      networking.firewall.allowedTCPPorts = [
        6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
        # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
        # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
      ];
      # networking.firewall.allowedUDPPorts = [
      #   # 8472 # k3s, flannel: required if using multi-node for inter-node networking
      # ];
      services.k3s.enable = true;
      services.k3s.role = "server";
      services.k3s.extraFlags = toString [
        "--node-name nixos"
        "--write-kubeconfig-mode 0644"
        # "--debug" # Optionally add additional args to k3s
      ];
      services.k3s.containerdConfigTemplate = ''
        {{ template "base" . }}

        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
          privileged_without_host_devices = false
          runtime_engine = ""
          runtime_root = ""
          runtime_type = "io.containerd.runc.v2"
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
          BinaryName = "${pkgs.nvidia-container-toolkit.tools}/bin/nvidia-container-runtime.cdi"
      '';
      systemd.services.k3s.wantedBy = lib.mkForce [ ];
      # Or disable the firewall altogether.
      # networking.firewall.enable = false;

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "26.05"; # Did you read the comment?

    };
}
