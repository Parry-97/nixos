{ ... }:
{
  # Run the Ghostty daemon on the NVIDIA GPU via PRIME render offload.
  # Applied as a drop-in so it merges into the unit shipped by the ghostty
  # package (~/.config/systemd/user/app-com.mitchellh.ghostty.service.d/override.conf).
  home.file.".config/systemd/user/app-com.mitchellh.ghostty.service.d/override.conf".text = ''
    [Service]
    Environment="__NV_PRIME_RENDER_OFFLOAD=1"
    Environment="__GLX_VENDOR_LIBRARY_NAME=nvidia"
  '';
}
