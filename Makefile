crio ?= /run/containerd/containerd.sock

kubeseal_args =--controller-name sealed-secrets-controller --controller-namespace kube-system -o yaml

host = $(shell echo $(HOSTNAME) | tr A-Z a-z)

## One Click Deploy ############################################################
infra: tf-init tf-apply

minimal:
	@echo "Minimal"

full:
	@echo "Full"

## Terraform ###################################################################
tf-init:
	@terraform -chdir=infrastructure init -reconfigure -upgrade

tf-plan:
	@terraform -chdir=infrastructure plan

tf-apply:
	@terraform -chdir=infrastructure apply

tf-destroy:
	@terraform -chdir=infrastructure destroy

## Kubeadm #####################################################################
kubeadm-init:
	echo sudo kubeadm init \
		--pod-network-cidr="$${KUBEADM_POD_NETWORK_CIDR}" \
		--service-cidr="$${KUBEADM_SVC_NETWORK_CIDR}" \
		--cri-socket="$(crio)" \
		--apiserver-advertise-address=0.0.0.0 \
		--control-plane-endpoint="$(host)"

	mkdir -p $$HOME/.kube
	sudo cp -i /etc/kubernetes/admin.conf $$HOME/.kube/config
	sudo chown $$(id -u):$$(id -g) $$HOME/.kube/config

	kubectl taint nodes --all node-role.kubernetes.io/master-

kubeadm-deinit:
	sudo kubeadm reset
	sudo rm -rf /etc/cni/net.d
	sudo iptables -F
	sudo iptables -t nat -F
	sudo iptables -t mangle -F
	sudo iptables -X

## Calico ######################################################################
calico-init:
	@kubectl apply -k deployment/calico

calico-deinit:
	@kubectl apply -k deployment/calico

## MetalLB #####################################################################
metal-lb-init:
	@kubectl get configmap kube-proxy -n kube-system -o yaml | \
		sed -e "s/strictARP: false/strictARP: true/" | \
		kubectl apply -f - -n kube-system
	@envsubst < deployment/metal-lb/base/metal-lb.config.yaml.tmpl > deployment/metal-lb/base/metal-lb.config.yaml
	@kubectl apply -k deployment/metal-lb

metal-lb-deinit:
	@kubectl get configmap kube-proxy -n kube-system -o yaml | \
		sed -e "s/strictARP: true/strictARP: false/" | \
		kubectl apply -f - -n kube-system
	@kubectl delete -k deployment/metal-lb

## ArgoCD ######################################################################
argo-cd-init:
	@kubectl apply -k deployment/argo-cd

argo-cd-app:
	@kubectl apply -k deployment/argo-cd/app

argo-cd-token:
	@kubectl -n argo-cd get secret argocd-initial-admin-secret \
		 -o go-template="{{.data.password | base64decode}}"

argo-cd-sealed-secret:
	@kubeseal $(kubeseal_args) \
		< deployment/argo-cd/base/argo-cd.secret.yaml \
		> deployment/argo-cd/base/argo-cd.sealedsecret.yaml

argo-cd-apps: argo-cd-app argo-rollouts-app bookinfo-app code-server-app cert-manager-app httpbin-app istio-app jaeger-app jupyter-app kiali-app kubernetes-dashboard-app metrics-server-app sealed-secret-app sleep-app sonarqube-app tekton-pipelines-app vault-app

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
	@kubectl label namespace default istio-injection=enabled --overwrite=true

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

## Kube Prometheus Stack #######################################################
kube-prometheus-stack-init:
	@kubectl apply -k deployment/kube-prometheus-stack

kube-prometheus-stack-app:
	@kubectl apply -k deployment/kube-prometheus-stack/app

kube-prometheus-stack-deinit:
	@kubectl delete -k deployment/kube-prometheus-stack

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

## Pomerium ####################################################################
pomerium-init:
	@kubectl apply -k deployment/pomerium

pomerium-app:
	@kubectl apply -k deployment/pomerium/app

pomerium-sealed-secret:
	@kubeseal $(kubeseal_args) \
		< deployment/pomerium/base/pomerium.secret.yaml \
		> deployment/pomerium/base/pomerium.sealedsecret.yaml

pomerium-deinit:
	@kubectl delete -k deployment/pomerium

## Sealed Secret ###############################################################
sealed-secret-init:
	@kubectl apply -k deployment/sealed-secret

sealed-secret-app:
	@kubectl apply -k deployment/sealed-secret/app

sealed-secret-deinit:
	@kubectl delete -k deployment/sealed-secret

sealed-secret-make: cert-manager-sealed-secret argo-cd-sealed-secret pomerium-sealed-secret

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

## Vault #######################################################################
vault-init:
	@kubectl apply -k deployment/vault

vault-app:
	@kubectl apply -k deployment/vault/app

vault-deinit:
	@kubectl delete -k deployment/vault
