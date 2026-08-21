{ self, inputs, ... }: {
  flake.nixosModules.niri = { pkgs, lib, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };
  };

  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        settings = {
          spawn-at-startup = [
            (lib.getExe self'.packages.myNoctalia)
          ];

          spawn-sh-at-startup = [
            ''
              wp=${lib.escapeShellArg (toString ./wallpapers/wallhaven_vpdyml.jpg)}
              for _ in $(seq 1 30); do
                if cur=$(${lib.getExe self'.packages.myNoctalia} ipc call wallpaper get all 2>/dev/null); then
                  case "$cur" in
                    *noctalia.png*|"")
                      ${lib.getExe self'.packages.myNoctalia} ipc call wallpaper set "$wp" all
                      ;;
                  esac
                  break
                fi
                sleep 1
              done
            ''
          ];

          xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

          input = {
            keyboard.xkb.layout = "us,it";
            touchpad = {
              tap = _: { };
              dwt = _: { };
              natural-scroll = _: { };
              click-method = "clickfinger";
            };
          };

          layout.gaps = 5;

          screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

          binds = {
            "Alt+Return".spawn-sh = "nvidia-offload ${lib.getExe pkgs.ghostty}";
            "Alt+Q".close-window = _: { };
            "Alt+S".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";

            "Alt+Shift+Slash".show-hotkey-overlay = _: { };

            "Alt+H".focus-column-left = _: { };
            "Alt+J".focus-window-down = _: { };
            "Alt+K".focus-window-up = _: { };
            "Alt+L".focus-column-right = _: { };
            "Alt+Left".focus-column-left = _: { };
            "Alt+Down".focus-window-down = _: { };
            "Alt+Up".focus-window-up = _: { };
            "Alt+Right".focus-column-right = _: { };
            "Alt+Home".focus-column-first = _: { };
            "Alt+End".focus-column-last = _: { };

            "Alt+Ctrl+H".move-column-left = _: { };
            "Alt+Ctrl+J".move-window-down = _: { };
            "Alt+Ctrl+K".move-window-up = _: { };
            "Alt+Ctrl+L".move-column-right = _: { };
            "Alt+Ctrl+Home".move-column-to-first = _: { };
            "Alt+Ctrl+End".move-column-to-last = _: { };

            "Alt+Shift+H".focus-monitor-left = _: { };
            "Alt+Shift+J".focus-monitor-down = _: { };
            "Alt+Shift+K".focus-monitor-up = _: { };
            "Alt+Shift+L".focus-monitor-right = _: { };

            "Alt+U".focus-workspace-down = _: { };
            "Alt+I".focus-workspace-up = _: { };
            "Alt+Page_Up".focus-workspace-up = _: { };
            "Alt+Page_Down".focus-workspace-down = _: { };
            "Alt+Shift+U".move-workspace-down = _: { };
            "Alt+Shift+I".move-workspace-up = _: { };
            "Alt+WheelScrollUp".focus-workspace-up = _: { };
            "Alt+WheelScrollDown".focus-workspace-down = _: { };

            "Alt+R".switch-preset-column-width = _: { };
            "Alt+Shift+R".switch-preset-column-width-back = _: { };
            "Alt+F".maximize-column = _: { };
            "Alt+Shift+F".fullscreen-window = _: { };
            "Alt+M".maximize-window-to-edges = _: { };
            "Alt+Shift+V".toggle-window-floating = _: { };
            # "Alt+Shift+V".switch-focus-between-floating-and-tiling = _: { };
            "Alt+C".center-column = _: { };
            "Alt+BracketLeft".consume-or-expel-window-left = _: { };
            "Alt+BracketRight".consume-or-expel-window-right = _: { };
            "Alt+Minus".set-column-width = "-10%";
            "Alt+Equal".set-column-width = "+10%";
            "Alt+W".toggle-column-tabbed-display = _: { };
            "Alt+O".toggle-overview = _: { };

            "Alt+Escape" = _: {
              props.allow-inhibiting = false;
              content.toggle-keyboard-shortcuts-inhibit = _: { };
            };
            "Super+Alt+L".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call lockScreen lock";
            "Alt+Shift+P".power-off-monitors = _: { };
            "Alt+Shift+E".quit = _: { };
            "Ctrl+Alt+Delete".quit = _: { };

            "Print".screenshot = _: { };
            "Ctrl+Print".screenshot-screen = _: { };
            "Alt+Print".screenshot-window = _: { };

            "XF86AudioRaiseVolume".spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
            "XF86AudioLowerVolume".spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
            "XF86AudioMute".spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            "XF86AudioMicMute".spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            "XF86AudioPlay".spawn-sh = "playerctl play-pause";
            "XF86AudioStop".spawn-sh = "playerctl stop";
            "XF86AudioPrev".spawn-sh = "playerctl previous";
            "XF86AudioNext".spawn-sh = "playerctl next";
            "XF86MonBrightnessUp".spawn-sh = "brightnessctl set +10%";
            "XF86MonBrightnessDown".spawn-sh = "brightnessctl set 10%-";
          }
          // builtins.listToAttrs (
            map (n: {
              name = "Alt+${toString n}";
              value = {
                focus-workspace = n;
              };
            }) (lib.genList (x: x + 1) 9)
          )
          // builtins.listToAttrs (
            map (n: {
              name = "Alt+Ctrl+${toString n}";
              value = {
                move-column-to-workspace = n;
              };
            }) (lib.genList (x: x + 1) 9)
          );
        };
      };
    };
}
