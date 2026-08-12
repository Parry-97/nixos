{ self, inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.myNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;
      settings = {
        appLauncher = {
          enableClipPreview = true;
          iconMode = "tabler";
          position = "center";
          showCategories = true;
          sortByMostUsed = true;
          terminalCommand = "nvidia-offload ghostty -e";
          viewMode = "list";
        };
        audio = {
          cavaFrameRate = 30;
          externalMixer = "pwvucontrol || pavucontrol";
          volumeStep = 5;
        };
        bar = {
          capsuleOpacity = 1;
          density = "comfortable";
          exclusive = true;
          floating = false;
          marginHorizontal = 0.25;
          marginVertical = 0.25;
          outerCorners = true;
          position = "top";
          showCapsule = false;
          showOutline = false;
          transparent = false;
          widgets = {
            center = [ ];
            left = [
              {
                colorizeDistroLogo = true;
                enableColorization = true;
                id = "ControlCenter";
                useDistroLogo = true;
              }
              {
                characterCount = 2;
                enableScrollWheel = true;
                followFocusedScreen = false;
                hideUnoccupied = true;
                id = "Workspace";
                labelMode = "none";
                showLabelsOnlyWhenOccupied = true;
              }
            ];
            right = [
              {
                hideWhenZero = false;
                id = "NotificationHistory";
                showUnreadBadge = true;
              }
              {
                displayMode = "alwaysShow";
                hideIfNotDetected = true;
                id = "Battery";
                warningThreshold = 20;
              }
              {
                displayMode = "forceOpen";
                id = "KeyboardLayout";
              }
              {
                formatHorizontal = "HH:mm ddd, MMM dd";
                formatVertical = "HH mm - dd MM";
                id = "Clock";
                usePrimaryColor = true;
              }
              {
                blacklist = [ ];
                colorizeIcons = false;
                drawerEnabled = true;
                hidePassive = false;
                id = "Tray";
                pinned = [ ];
              }
            ];
          };
        };
        general = {
          allowPanelsOnScreenWithoutBar = true;
          animationSpeed = 1;
          boxRadiusRatio = 1;
          compactLockScreen = false;
          dimmerOpacity = 0.15;
          enableShadows = true;
          language = "";
          lockOnSuspend = true;
          radiusRatio = 1;
          scaleRatio = 1;
          showHibernateOnLockScreen = false;
        };
        nightLight = {
          autoSchedule = true;
          dayTemp = "6500";
          enabled = false;
          nightTemp = "4000";
        };
        notifications = {
          enabled = true;
          location = "top_right";
          overlayLayer = true;
        };
        osd = {
          autoHideMs = 3000;
          enabled = true;
          enabledTypes = [
            0
            1
            2
            4
          ];
          location = "bottom";
          overlayLayer = true;
        };
        sessionMenu = {
          countdownDuration = 10000;
          enableCountdown = true;
          position = "center";
          powerOptions = [
            {
              action = "lock";
              countdownEnabled = true;
              enabled = true;
            }
            {
              action = "suspend";
              countdownEnabled = true;
              enabled = true;
            }
            {
              action = "hibernate";
              countdownEnabled = true;
              enabled = true;
            }
            {
              action = "reboot";
              countdownEnabled = true;
              enabled = true;
            }
            {
              action = "logout";
              countdownEnabled = true;
              enabled = true;
            }
            {
              action = "shutdown";
              countdownEnabled = true;
              enabled = true;
            }
          ];
          showHeader = true;
        };
        ui = {
          panelBackgroundOpacity = 1;
          panelsAttachedToBar = true;
          settingsPanelMode = "attached";
          tooltipsEnabled = true;
        };
        colorSchemes = {
          darkMode = true;
          predefinedScheme = "Ayu";
        };
        wallpaper = {
          enabled = true;
        };
      };
    };
  };
}
