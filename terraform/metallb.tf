
resource "kubernetes_namespace" "metallb_system" {
  metadata {
    name = "metallb-system"
  }
}

resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metallb"
  namespace  = kubernetes_namespace.metallb_system.metadata.0.name

  set {
    name  = "version"
    value = "0.13.10"
  }

  values =[
<<EOF
controller:
  nodeSelector:
    node-role.kubernetes.io/master: "true"
speaker:
  nodeSelector:
    node-role.kubernetes.io/master: "true"

EOF
  ]

  depends_on = [
    kubernetes_namespace.metallb_system
  ]
}

resource "kubectl_manifest" "metallb" {
    yaml_body = <<YAML
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: primary-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.50.15-192.168.50.49
  autoAssign: true
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - primary-pool
YAML
  depends_on = [
    helm_release.metallb
  ]
}
