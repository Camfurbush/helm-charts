resource "kubernetes_namespace" "longhorn-system" {
  metadata {
    name = "longhorn-system"
  }
  depends_on = [
    helm_release.ingress-nginx
  ]
}


resource "helm_release" "longhorn" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  namespace  = "longhorn-system"

  set {
    name  = "version"
    value = "1.4.0"
  }
  values =[
<<EOF
ingress:
  enabled: true
  host: longhorn.camfu.co
  tls: true
  tlsSecret: longhorn-secret

  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: true
EOF
  ]
  depends_on = [
    kubernetes_namespace.longhorn-system
  ]
}
