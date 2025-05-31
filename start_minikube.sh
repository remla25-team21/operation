#!/bin/bash

set -e  # Exit on error

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}===== Minikube Setup Script for Sentiment Analysis App =====${NC}"
echo -e "${YELLOW}This script will set up a complete environment with Minikube, Istio, and deploy the application.${NC}"
echo

# Check if necessary tools are installed
for tool in minikube kubectl helm istioctl; do
  if ! command -v $tool &> /dev/null; then
    echo -e "${RED}Error: $tool is not installed. Please install it first.${NC}"
    exit 1
  fi
done

echo -e "${BLUE}[1/7]${NC} Cleaning up any existing Minikube clusters..."
minikube delete --all > /dev/null 2>&1 || true

echo -e "${BLUE}[2/7]${NC} Starting Minikube..."
minikube start --memory=4096 --cpus=4 --driver=docker
minikube addons enable ingress
echo -e "${GREEN}Minikube started successfully!${NC}"

echo -e "${BLUE}[3/7]${NC} Installing Prometheus stack..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts > /dev/null 2>&1
helm repo update > /dev/null 2>&1
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
echo -e "${GREEN}Prometheus stack installed!${NC}"

echo -e "${BLUE}[4/7]${NC} Installing Istio and its add-ons..."
istioctl install -y
kubectl apply -f kubernetes/istio-addons/prometheus.yaml
kubectl apply -f kubernetes/istio-addons/jaeger.yaml
kubectl apply -f kubernetes/istio-addons/kiali.yaml
kubectl label ns default istio-injection=enabled --overwrite
echo -e "${GREEN}Istio installed!${NC}"

echo -e "${BLUE}[5/7]${NC} Deploying the application..."
GATEWAY_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

# Wait for the external IP to be assigned
ATTEMPTS=0
MAX_ATTEMPTS=30
while [ "$GATEWAY_IP" = "pending" ] && [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    echo -e "${YELLOW}Waiting for istio-ingressgateway external IP... (attempt $((ATTEMPTS+1))/${MAX_ATTEMPTS})${NC}"
    sleep 5
    GATEWAY_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    ATTEMPTS=$((ATTEMPTS+1))
done

if [ "$GATEWAY_IP" = "pending" ]; then
    echo -e "${YELLOW}No external IP found after waiting. Will use 'localhost' for deployment.${NC}"
    GATEWAY_IP="localhost"
fi

helm install my-sentiment-analysis ./kubernetes/helm/sentiment-analysis --set istio.ingressGateway.host=$GATEWAY_IP
echo -e "${GREEN}Application deployed!${NC}"

echo -e "${BLUE}[6/7]${NC} Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod --all --timeout=300s || true
echo -e "${GREEN}All ready pods are now available!${NC}"

# Start minikube tunnel in background and save PID
echo -e "${BLUE}[7/7]${NC} Starting Minikube tunnel in the background..."
minikube tunnel > /dev/null 2>&1 &
TUNNEL_PID=$!
echo $TUNNEL_PID > minikube_tunnel.pid
echo -e "${GREEN}Minikube tunnel started (PID: $TUNNEL_PID)${NC}"

# Get the actual external IP after tunnel is established
sleep 5
EXTERNAL_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "localhost")

echo
echo -e "${GREEN}===========================${NC}"
echo -e "${GREEN}Setup Complete! Access your services:${NC}"
echo -e "${YELLOW}Access your application at:${NC} http://$EXTERNAL_IP"
echo -e "${YELLOW}Prometheus dashboard:${NC} Run in a new terminal: kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo -e "${YELLOW}Grafana dashboard:${NC} Run in a new terminal: kubectl -n monitoring port-forward service/prometheus-grafana 3300:80"
echo -e "${YELLOW}Kiali dashboard:${NC} Run in a new terminal: kubectl -n istio-system port-forward svc/kiali 20001:20001"
echo
echo -e "${YELLOW}To stop the Minikube tunnel when done:${NC} kill $(cat minikube_tunnel.pid)"
echo -e "${GREEN}===========================${NC}"
