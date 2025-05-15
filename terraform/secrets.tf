resource "kubernetes_secret" "ssh_key" {
  metadata {
    name      = "private-repo"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  type = "Opaque"

  data = {
    "sshPrivateKey" = data.vault_generic_secret.internal_generic.data["ssh_private_key_file"]
    "type"          = "git"
    "url"           = "git@github.com:camfu-co/hl_helm.git"
  }
}

resource "kubernetes_secret" "ghcr" {
  metadata {
    name = "docker-cfg"
    namespace = "lightnovel-crawler"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          "username" = "Camfurbush"
          "password" = data.vault_generic_secret.github_token.data["GITHUB_TOKEN"]
        }
      }
    })
  }
}
