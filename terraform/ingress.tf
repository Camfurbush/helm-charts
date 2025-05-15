resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "kube-system"

  set {
    name  = "version"
    value = "4.7.0"
  }

  depends_on = [
    helm_release.metallb
  ]
  values =[
<<EOF
controller:
  nodeSelector:
    node-role.kubernetes.io/master: "true"
  extraArgs:
    enable-ssl-passthrough: true
EOF
  ]
}
