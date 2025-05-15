resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
  depends_on = [
    helm_release.ingress-nginx
  ]
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert-manager.metadata.0.name

  set {
    name  = "version"
    value = "1.12.1"
  }
  values = [
<<EOF
installCRDs: true

nodeSelector:
  node-role.kubernetes.io/master: "true"

podDnsConfig:
  nameservers:
    - 108.162.194.25
dnsPolicy: None
extraArgs:
  - --default-issuer-name=letsencrypt-prod
  - --default-issuer-kind=ClusterIssuer
EOF
]
  depends_on = [
    kubernetes_namespace.cert-manager
  ]
}


resource "kubectl_manifest" "cert-manager-issuer" {
  yaml_body = <<EOT
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
  namespace: cert-manager
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: Camfurbush@gmail.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - dns01:
         cloudflare:
           email: Camfurbush@gmail.com
           apiTokenSecretRef:
             name: cloudflare-api-token-secret
             key: api-token
EOT

  depends_on = [
    helm_release.cert-manager
  ]
}

resource "kubectl_manifest" "cloudflare_api_key" {
  yaml_body = <<EOT
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token-secret
  namespace: cert-manager
type: Opaque
stringData:
  api-token: ${data.vault_generic_secret.cloudflare_api_key.data["api_token"]}
EOT

  depends_on = [
    helm_release.cert-manager
  ]
}