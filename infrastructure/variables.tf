variable "dns_domain" {
  type        = string
  description = <<EOF
EOF

  default = "anhdle14.me"
}

variable "device_name" {
  type        = string
  description = <<EOF
  The main device's name that is hosting services in deployment/.
EOF

  default = "macbook.anhdle14.github"
}

variable "labels" {
  type        = map(string)
  description = <<EOF
EOF

  default = {}
}
