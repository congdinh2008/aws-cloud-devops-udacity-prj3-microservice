#!/bin/bash

# Add the Bitnami Helm repository
helm repo add $1 https://charts.bitnami.com/bitnami &&\

# Install PostgreSQL
helm install --set primary.persistence.enabled=false postgres $1/postgresql