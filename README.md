# Three-Tier Web Application Deployment on GCP GKE using GCP GKE, ArgoCD, Prometheus, Grafana, and Jenkins

Repository for creating Google Kubernetes Engine with IAC (Terraform).

sudo apt-get install google-cloud-cli-gke-gcloud-auth-plugin

gcloud container clusters get-credentials devopsproject --region us-east4 --project gcp-proect-id

kubectl create namespace argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

sudo apt install jq -y

export ARGOCD_SERVER='kubectl get svc argocd-server -n argocd -o json | jq - raw-output '.status.loadBalancer.ingress[0].hostname''

export ARGO_PWD='kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d'

echo $ARGO_PWD