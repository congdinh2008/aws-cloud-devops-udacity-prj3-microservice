## Apply env variables and secrets
kubectl apply -f ./deployment/env-secret.yaml
kubectl apply -f ./deployment/env-configmap.yaml

## Deployments - Double check the Dockerhub image name and version in the deployment files
kubectl apply -f ./deployment/app-deployment.yaml

## Service
kubectl apply -f ./deployment/app-service.yaml
