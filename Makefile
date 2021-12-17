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

## ArgoCD ######################################################################
argo-cd-init:
	@kubectl apply -k deployment/argo-cd

argo-cd-app:
	@kubectl apply -k deployment/argo-cd/app

argo-cd-token:
	@kubectl -n argo-cd get secret argocd-initial-admin-secret \
		 -o go-template="{{.data.password | base64decode}}"

argo-cd-sealed-secret:
	@echo ": argo-cd secrets"
	@kubeseal $(kubeseal_args) \
		< deployment/argo-cd/base/argo-cd.secret.yaml \
		> deployment/argo-cd/base/argo-cd.sealedsecret.yaml

argo-cd-deinit:
	@kubectl delete -k deployment/argo-cd

## Argo Rollouts ###############################################################
argo-rollouts-init:
	@kubectl apply -k deployment/argo-rollouts

argo-rollouts-app:
	@kubectl apply -k deployment/argo-rollouts/app

argo-rollouts-deinit:
	@kubectl delete -k deployment/argo-rollouts

## Bookinfo ####################################################################
bookinfo-init:
	@kubectl apply -k deployment/bookinfo

bookinfo-app:
	@kubectl apply -k deployment/bookinfo/app

bookinfo-deinit:
	@kubectl delete -k deployment/bookinfo

## Code Server #################################################################
code-server-init:
	@kubectl apply -k deployment/code-server

code-server-app:
	@kubectl apply -k deployment/code-server/app

code-server-deinit:
	@kubectl delete -k deployment/code-server

## Cert-Manager ################################################################
cert-manager-init:
	@kubectl apply -k deployment/cert-manager
	@sleep 20
	@kubectl apply -k deployment/cert-manager/resources

cert-manager-app:
	@kubectl apply -k deployment/cert-manager/app

cert-manager-sealed-secret:
	@echo "INFO cert-manager secrets"
	@kubeseal $(kubeseal_args) \
		< deployment/cert-manager/base/cert-manager.secret.yaml \
		> deployment/cert-manager/base/cert-manager.sealedsecret.yaml

cert-manager-deinit:
	@kubectl delete -k deployment/cert-manager --all

## Httpbin #####################################################################
httpbin-init:
	@kubectl apply -k deployment/httpbin

httpbin-app:
	@kubectl apply -k deployment/httpbin/app

httpbin-deinit:
	@kubectl delete -k deployment/httpbin

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

istio-app:
	@kubectl apply -k deployment/istio/app

istio-deinit:
	@kubectl delete -k deployment/istio
	@kubectl delete -k deployment/istio/operator

## Jaeger ######################################################################
jaeger-init:
	@kubectl apply -k deployment/jaeger/operator
	@sleep 10
	@kubectl apply -k deployment/jaeger

jaeger-app:
	@kubectl apply -k deployment/jaeger/app

jaeger-deinit:
	@kubectl delete -k deployment/jaeger/operator --all

## Jupyter #####################################################################
jupyter-init:
	@kubectl apply -k deployment/jupyter

jupyter-app:
	@kubectl apply -k deployment/jupyter/app

jupyter-deinit:
	@kubectl delete -k deployment/jupyter

## Kiali #######################################################################
kiali-operator-init:
	@kubectl apply -k deployment/kiali/operator

kiali-init:
	@kubectl apply -k deployment/kiali

kiali-app:
	@kubectl apply -k deployment/kiali/app

## Kubernetes Dashboard ########################################################
kubernetes-dashboard-init:
	@kubectl apply -k deployment/kubernetes-dashboard

kubernetes-dashboard-app:
	@kubectl apply -k deployment/kubernetes-dashboard/app

kubernetes-dashboard-token:
	@kubectl -n kubernetes-dashboard get secret \
		`kubectl -n kubernetes-dashboard get sa/admin -o jsonpath="{.secrets[0].name}"` \
		 -o go-template="{{.data.token | base64decode}}"

## Metrics Server ##############################################################
metrics-server-init:
	@kubectl apply -k deployment/metrics-server

metrics-server-app:
	@kubectl apply -k deployment/metrics-server/app

metrics-server-deinit:
	@kubectl delete -k deployment/metrics-server

## Sealed Secret ###############################################################
sealed-secret-init:
	@kubectl apply -k deployment/sealed-secret

sealed-secret-app:
	@kubectl apply -k deployment/sealed-secret/app

sealed-secret-deinit:
	@kubectl delete -k deployment/sealed-secret

sealed-secret-make: cert-manager-sealed-secret argo-cd-sealed-secret

## Kube Prometheus Stack #######################################################
kube-prometheus-stack-init:
	@kubectl apply -k deployment/kube-prometheus-stack

kube-prometheus-stack-app:
	@kubectl apply -k deployment/kube-prometheus-stack/app

kube-prometheus-stack-deinit:
	@kubectl apply -k deployment/kube-prometheus-stack

## Sleep #######################################################################
sleep-init:
	@kubectl apply -k deployment/sleep

sleep-app:
	@kubectl apply -k deployment/sleep/app

sleep-deinit:
	@kubectl delete -k deployment/sleep

## Sleep #######################################################################
sonarqube-init:
	@kubectl apply -k deployment/sonarqube

sonarqube-app:
	@kubectl apply -k deployment/sonarqube/app

sonarqube-deinit:
	@kubectl delete -k deployment/sonarqube

## Tekton Pipelines ############################################################
tekton-pipelines-init:
	@kubectl apply -k deployment/tekton-pipelines

tekton-pipelines-app:
	@kubectl apply -k deployment/tekton-pipelines/app

tekton-pipelines-deinit:
	@kubectl delete -k deployment/tekton-pipelines
