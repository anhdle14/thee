# The current device that is hosting all the services under deployment/.
data "tailscale_devices" "all" {
  name_prefix = ""
}

data "tailscale_device" "this" {
  name = var.device_name
}
