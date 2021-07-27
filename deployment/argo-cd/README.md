# Argo CD

This is the deployment folder follow the App of Apps architecture.

## How ArgoCD SealedSecret Work?

## How To Generate The ArgoCD SealedSecret?

```sh
$ kubectl get secret -n argo-cd argocd-secret -o yaml > argo-cd.secret.yaml
```

The file should look something like this:

```yaml
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  annotations:
    sealedsecrets.bitnami.com/managed: "true"
  labels:
    # These labels are here to fix OutOfSyncs.
    # This should be updated if kustomization.yaml upgrade to new Argo CD version.
    app: argo-cd
    version: v2.1.5
    app.kubernetes.io/part-of: argocd

    argocd.argoproj.io/instance: argo-cd
    app.kubernetes.io/instance: argo-cd
    app.kubernetes.io/name: argocd-secret
  name: argocd-secret
  namespace: argo-cd
data:
  server.secretkey: ---REDACTED---
  oidc.auth0.clientID: ---REDACTED---
  oidc.auth0.clientSecret: ---REDACTED---
```

Then you can go to [kustomization.yaml](./kustomization.yaml) and uncommented these line:

```yaml
# IMPORTANT: COMMENT THIS FOR THE FIRST RUN. PLEASE FOLLOW THE GUIDELINE TO GENERATE THIS FILE.
- base/argo-cd.sealedsecret.yaml

# IMPORTANT: COMMENT THIS FOR THE FIRST RUN. PLEASE FOLLOW THE GUIDELINE TO GENERATE THIS FILE.
- path: patches/argo-cd.secret.json
  target:
    version: v1
    kind: Secret
    name: argocd-secret
```
