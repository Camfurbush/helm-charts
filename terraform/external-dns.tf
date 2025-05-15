resource "kubernetes_namespace" "external-dns" {
  metadata {
    name = "external-dns"
  }
  depends_on = [
    helm_release.ingress-nginx
  ]
}

resource "kubectl_manifest" "external-dns-sa" {
  yaml_body = <<EOT
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
  namespace: external-dns
EOT

  depends_on = [
    kubernetes_namespace.external-dns
  ]
}


resource "kubectl_manifest" "external-dns-cluster-role" {
  yaml_body = <<EOT
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
  namespace: external-dns
rules:
- apiGroups: [""]
  resources: ["services","endpoints","pods"]
  verbs: ["get","watch","list"]
- apiGroups: ["extensions","networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get","watch","list"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["list","watch"]
EOT

  depends_on = [
    kubernetes_namespace.external-dns
  ]
}


resource "kubectl_manifest" "external-dns-role-binding" {
  yaml_body = <<EOT
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
  namespace: external-dns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
- kind: ServiceAccount
  name: external-dns
  namespace: external-dns
EOT
  depends_on = [
    kubernetes_namespace.external-dns
  ]
}

resource "kubectl_manifest" "external-dns-deployment" {
  yaml_body = <<EOT
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  namespace: external-dns
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      nodeSelector:
        node-role.kubernetes.io/master: "true"
      containers:
      - name: external-dns
        image: registry.k8s.io/external-dns/external-dns:v0.13.1
        args:
        - --source=ingress
        - --domain-filter=camfu.co # (optional) limit to only example.com domains; change to match the zone created above.
        - --provider=cloudflare
        env:
        - name: CF_API_KEY
          value: ${data.vault_generic_secret.cloudflare_api_key.data["api_key"]}
        - name: CF_API_EMAIL
          value: Camfurbush@gmail.com
EOT
  depends_on = [
    kubernetes_namespace.external-dns
  ]
}
