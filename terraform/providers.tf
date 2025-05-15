terraform {
  backend "s3" {}
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    vault = {
      source = "hashicorp/vault"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

provider "kubectl" {
  config_path    = "/root/.kube/config"
}


provider "kubernetes" {
  config_path    = "/root/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "/root/.kube/config"
  }
}

provider "vault" {}

data "vault_generic_secret" "cloudflare_api_key" {
  path = "external/cloudflare"
}

data "vault_generic_secret" "github_token" {
  path = "external/github"
}

data "vault_generic_secret" "windscribe_password" {
  path = "external/windscribe"
}

data "vault_generic_secret" "internal_generic" {
  path = "internal/generic"
}