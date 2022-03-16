terraform {
  required_providers {
    tailscale = {
      source  = "davidsbond/tailscale"
      version = "0.6.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 4.5.0, < 5.0.0"
    }
  }
}

# NOTE: All of the envvars are set in .envrc and using direnv to automatically applied with `direnv allow`.

provider "tailscale" {
  # TAILSCALE_API_KEY can be used instead of this
  # api_key = "my_api_key"

  # TAILSCALE_TAILNET can be used instead of this
  # https://registry.terraform.io/providers/davidsbond/tailscale/latest/docs#required
  # tailnet = "anhdle14@github"
}

provider "google" {
  # GOOGLE_PROJECT
  # project = "project-id"

  # GOOGLE_REGION
  #region = "us-central1"

  # GOOGLE_ZONE
  #zone = "us-central1-c"
}
