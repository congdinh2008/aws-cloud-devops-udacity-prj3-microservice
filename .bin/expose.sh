BACKEND_DEPLOYMENT_NAME="backend-coworking"

# Kubectl expose
kubectl expose deployment $BACKEND_DEPLOYMENT_NAME --type=LoadBalancer --name=publicbackend