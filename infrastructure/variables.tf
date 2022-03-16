variable "dns_domain" {
  type        = string
  description = <<EOF
EOF

  default = "anhdle14.me"
}

variable "host_machine" {
  type        = string
  description = <<EOF
  The main device's name that is hosting services in deployment/.
EOF

  default = "arch.anhdle14.github"
}

variable "load_balancer_ip" {
  type        = string
  description = <<EOF
  The Istio load balancer's external IP.

  NOTE: This should come after the kubernetes cluster has been created.
EOF

  default = ""
}

variable "tailscale_subnet_cidr" {
  type        = string
  description = <<EOF
  The TailScale subnet for MetalLB to use. You can learn more from here: https://tailscale.com/kb/1019/subnets/.
EOF
}

variable "labels" {
  type        = map(string)
  description = <<EOF
EOF

  default = {}
}
