resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [
    helm_release.ingress-nginx
  ]
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata.0.name

  set {
    name  = "version"
    value = "5.36.1"
  }
  values = [
<<EOF
installCRDs: true

global:
  nodeSelector:
    node-role.kubernetes.io/master: "true"

server:
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: nginx
      kubernetes.io/tls-acme: "true"
      nginx.ingress.kubernetes.io/ssl-passthrough: "true"
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    hosts:
      - argocd.camfu.co
    tls:
      - secretName: argocd-secret
        hosts:
          - argocd.camfu.co

configs:
  cm:
    url: https://argocd.camfu.co
    admin.enabled: "true"
  secret:
    argocdServerAdminPassword: ${bcrypt(data.vault_generic_secret.internal_generic.data["password"])}
EOF
]
  depends_on = [
    kubernetes_namespace.argocd
  ]
}

resource "helm_release" "argocd-apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = kubernetes_namespace.argocd.metadata.0.name

  set {
    name  = "version"
    value = "0.0.9"
  }
  values = [
<<EOF
applications:
  - name: app-of-apps
    namespace: argocd
    additionalLabels: {}
    finalizers:
    - resources-finalizer.argocd.argoproj.io
    project: app-of-apps
    source:
      repoURL: git@github.com:camfu-co/hl_helm.git
      targetRevision: HEAD
      path: argocd
    destination:
      server: https://kubernetes.default.svc
      namespace: argocd
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
projects:
  - name: app-of-apps
    namespace: argocd
    additionalLabels: {}
    additionalAnnotations: {}
    finalizers:
    - resources-finalizer.argocd.argoproj.io
    description: App-of-apps
    # Deny all cluster-scoped resources from being created, except for Namespace
    clusterResourceWhitelist:
    - group: '*'
      kind: '*'
    # Project description
    description: Example infrastructure project
    # Permit applications to install wherever
    destinations:
    - namespace: '*'
      server: '*'
    # Allow manifests to deploy from any Git repos
    sourceRepos:
    - '*'
EOF
]
  depends_on = [
    helm_release.argocd
  ]
}
