set -e

LOCAL_PORT=5432
TYPE_NAME=udacity-postgresql
REMOTE_PORT=5432

POSTGRES_PASSWORD=$(kubectl get secret --namespace default $TYPE_NAME -o jsonpath="{.data.postgres-password}" | base64 -d)
kubectl port-forward --namespace default svc/$TYPE_NAME $LOCAL_PORT:$REMOTE_PORT > /dev/null 2>&1 &

pid=$!
echo pid: $pid

# kill the port-forward regardless of how this script exits
trap '{
    # if variable $pid is empty, do nothing
    if ps -p $pid > /dev/null; then
        echo "pid is set"
        echo "killing $pid"
        kill $pid
    else
        echo "pid is unset"
    fi
}' EXIT

# wait for $LOCAL_PORT to become available
while ! nc -vz localhost $LOCAL_PORT > /dev/null 2>&1 ; do
    echo "Waiting for Kubectl $LOCAL_PORT to become available..."
    sleep 1
done

PGPASSWORD=$POSTGRES_PASSWORD psql --host 127.0.0.1 -U postgres -d postgres -p 5432 < ./db/1_create_tables.sql &&\
PGPASSWORD=$POSTGRES_PASSWORD psql --host 127.0.0.1 -U postgres -d postgres -p 5432 < ./db/2_seed_users.sql &&\
PGPASSWORD=$POSTGRES_PASSWORD psql --host 127.0.0.1 -U postgres -d postgres -p 5432 < ./db/3_seed_tokens.sql