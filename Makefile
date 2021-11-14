kubeseal_args=--controller-name sealed-secrets-controller --controller-namespace kube-system -o yaml

## Check CLI ###################################################################
check:
	@echo ": kubectl version"
	@kubectl version --short
	@echo ": istioctl version"
	@istioctl version --short --remote=false
	@echo ": kubeseal version"
	@kubeseal --version
	@echo ": istio-injection=enabled for default namespace"
	@kubectl label namespace default istio-injection=enabled --overwrite

## Metrics Server ##############################################################
metrics-server-init:
	@kubectl apply -k deployment/metrics-server

metrics-server-deinit:
	@kubectl delete -k deployment/metrics-server

## Sealed Secret ###############################################################
sealed-secret-init:
	@kubectl apply -k deployment/sealed-secret

sealed-secret-make: cert-manager-sealed-secret argo-cd-sealed-secret

## Cert-Manager ################################################################
cert-manager-init:
	@kubectl apply -k deployment/cert-manager
	@sleep 20
	@kubectl apply -k deployment/cert-manager/resources

cert-manager-sealed-secret:
	@echo "INFO cert-manager secrets"
	@kubeseal $(kubeseal_args) \
		< deployment/cert-manager/base/cert-manager.secret.yaml \
		> deployment/cert-manager/base/cert-manager.sealedsecret.yaml

cert-manager-deinit:
	@kubectl delete -k deployment/cert-manager --all

## Istio #######################################################################
# https://istio.io/latest/docs/setup/install/operator/
istio-operator-init:
	@istioctl version --remote=false
	@istioctl operator init
	@kubectl apply -k deployment/istio/operator

# We need to separate this because it will take 90~120s for operator to deploy
istio-init:
	@istioctl verify-install
	@kubectl apply -k deployment/istio

## ArgoCD ######################################################################
argo-cd-init:
	@kubectl apply -k deployment/argo-cd

argo-cd-token:
	@kubectl -n argo-cd get secret argocd-initial-admin-secret \
		 -o go-template="{{.data.password | base64decode}}"

argo-cd-sealed-secret:
	@echo ": argo-cd secrets"
	@kubeseal $(kubeseal_args) \
		< deployment/argo-cd/base/argo-cd.secret.yaml \
		> deployment/argo-cd/base/argo-cd.sealedsecret.yaml

## Tekton Pipelines ############################################################
tekton-pipelines-init:
	@kubectl apply -k deployment/tekton-pipelines

tekton-pipelines-deinit:
	@kubectl delete -k deployment/tekton-pipelines

## Httpbin #####################################################################
httpbin-init:
	@kubectl apply -k deployment/httpbin

httpbin-deinit:
	@kubectl delete -k deployment/httpbin

## Argo Rollouts ###############################################################
argo-rollouts-init:
	@kubectl apply -k deployment/argo-rollouts

argo-rollouts-deinit:
	@kubectl delete -k deployment/argo-rollouts

## Jaeger ######################################################################
jaeger-init:
	@kubectl apply -k deployment/jaeger/operator
	@sleep 10
	@kubectl apply -k deployment/jaeger

jaeger-deinit:
	@kubectl delete -k deployment/jaeger/operator --all

## Kiali #######################################################################
kiali-operator-init:
	@kubectl apply -k deployment/kiali/operator

kiali-init:
	@kubectl apply -k deployment/kiali

## Kube Prometheus Stack #######################################################
kube-prometheus-stack-init:
	@kubectl apply -k deployment/kube-prometheus-stack

kube-prometheus-stack-deinit:
	@kubectl apply -k deployment/kube-prometheus-stack

## Kubernetes Dashboard ########################################################
kubernetes-dashboard-init:
	@kubectl apply -k deployment/kubernetes-dashboard

kubernetes-dashboard-token:
	@kubectl -n kubernetes-dashboard get secret \
		`kubectl -n kubernetes-dashboard get sa/admin -o jsonpath="{.secrets[0].name}"` \
		 -o go-template="{{.data.token | base64decode}}"

## Code Server #################################################################
code-server-init:
	@kubectl apply -k deployment/code-server

code-server-deinit:
	@kubectl delete -k deployment/code-server

## Jupyter #####################################################################
jupyter-init:
	@kubectl apply -k deployment/jupyter

jupyter-deinit:
	@kubectl delete -k deployment/jupyter

## Sleep #######################################################################
sleep-init:
	@kubectl apply -k deployment/sleep

sleep-deinit:
	@kubectl delete -k deployment/sleep
