# The current device that is hosting all the services under deployment/.
data "tailscale_devices" "all" {
  name_prefix = ""
}

data "tailscale_device" "this" {
  name = var.host_machine
}

resource "tailscale_device_subnet_routes" "this" {
  device_id = data.tailscale_device.this.id
  routes    = [var.tailscale_subnet_cidr]
}
