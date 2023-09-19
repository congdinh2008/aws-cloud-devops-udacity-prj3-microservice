# Set up Bitnami Repository
helm repo add udacity-pr3 https://charts.bitnami.com/bitnami

# Install PostgreSQL Helm Chart
helm install udacity-postgre udacity-pr3/postgresql

# The password can be retrieved with the following command:
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default udacity-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
echo $POSTGRES_PASSWORD

# Connecting Via Port Forwarding
kubectl port-forward --namespace default svc/udacity-postgresql 5432:5432 & 
PGPASSWORD=ZWhUiLHn1a psql --host 127.0.0.1 -U postgres -d postgres -p 5432

# Connecting Via a Pod

kubectl exec -it udacity-postgre-postgresql-0 bash 
PGPASSWORD="jVQXWgZXj6" psql postgres://postgres@udacity-postgresql:5432/postgres -c \l

kubectl port-forward svc/udacity-postgresql 5432:5432

kubectl port-forward --namespace default svc/udacity-postgresql 5432:5432 &
    PGPASSWORD=ZWhUiLHn1a psql --host 127.0.0.1 -U postgres -d postgres -p 5432 < ./db/2_seed_users.sql

DB_USERNAME=postgres DB_PASSWORD=jVQXWgZXj6 python app.py

# Expose the Backend API to the Internet
kubectl expose deployment backend-coworking --type=LoadBalancer --name=publicbackend

kubectl exec --stdin --tty postgres-postgresql-0 -- /bin/bash

ClusterName=udacity-prj3-eks
RegionName=us-east-1
FluentBitHttpPort='2020'
FluentBitReadFromHead='Off'
[[ ${FluentBitReadFromHead} = 'On' ]] && FluentBitReadFromTail='Off'|| FluentBitReadFromTail='On'
[[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='Off' || FluentBitHttpServer='On'
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml | sed 's/{{cluster_name}}/'${ClusterName}'/;s/{{region_name}}/'${RegionName}'/;s/{{http_server_toggle}}/"'${FluentBitHttpServer}'"/;s/{{http_server_port}}/"'${FluentBitHttpPort}'"/;s/{{read_from_head}}/"'${FluentBitReadFromHead}'"/;s/{{read_from_tail}}/"'${FluentBitReadFromTail}'"/' | kubectl apply -f -