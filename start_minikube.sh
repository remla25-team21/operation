#!/bin/bash

set -e  # Exit on error

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Default step is not set - user must specify
STEP=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --step)
      STEP="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Error: Unknown parameter: $1${NC}"
      echo -e "${YELLOW}Usage: $0 --step 1|2${NC}"
      exit 1
      ;;
  esac
done

# Check if step is provided and valid
if [[ "$STEP" != "1" && "$STEP" != "2" ]]; then
    echo -e "${RED}Error: You must specify which step to run${NC}"
    echo -e "${YELLOW}Usage: $0 --step 1|2${NC}"
    echo -e "${YELLOW}  --step 1: Setup infrastructure (Minikube, Prometheus, Istio)${NC}"
    echo -e "${YELLOW}  --step 2: Deploy application${NC}"
    exit 1
fi

echo -e "${BLUE}===== Minikube Setup Script for Sentiment Analysis App =====${NC}"

# Check if necessary tools are installed
for tool in minikube kubectl helm istioctl; do
if ! command -v $tool &> /dev/null; then
    echo -e "${RED}Error: $tool is not installed. Please install it first.${NC}"
    exit 1
fi
done
echo -e "${GREEN}All necessary tools are installed.${NC}"

# Step 1: Infrastructure setup
if [[ "$STEP" == "1" ]]; then
  echo -e "${BLUE}[STEP 1] Setting up infrastructure...${NC}"

  echo -e "${BLUE}[1/4]${NC} Cleaning up any existing Minikube clusters..."
  minikube delete --all > /dev/null 2>&1 || true

  echo -e "${BLUE}[2/4]${NC} Starting Minikube..."
  minikube start --memory=4096 --cpus=4 --driver=docker
  minikube addons enable ingress
  echo -e "${GREEN}Minikube started successfully!${NC}"
  echo -e "${BLUE}[2.5/4]${NC} Creating /mnt/shared inside Minikube..."
  minikube ssh -- 'sudo mkdir -p /mnt/shared && sudo chmod 777 /mnt/shared && echo "created by setup script" | sudo tee /mnt/shared/init.txt > /dev/null'
  echo -e "${GREEN}/mnt/shared prepared in Minikube VM!${NC}"

  echo -e "${BLUE}[3/4]${NC} Installing Prometheus stack..."
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts > /dev/null 2>&1
  helm repo update > /dev/null 2>&1
  helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
  echo -e "${GREEN}Prometheus stack installed!${NC}"

  echo -e "${BLUE}[4/4]${NC} Installing Istio and its add-ons..."
  istioctl install -y
  kubectl apply -f kubernetes/istio-addons/prometheus.yaml
  kubectl apply -f kubernetes/istio-addons/jaeger.yaml
  kubectl apply -f kubernetes/istio-addons/kiali.yaml
  kubectl label ns default istio-injection=enabled --overwrite
  echo -e "${GREEN}Istio installed!${NC}"

  kubectl apply -f kubernetes/rate-limit.yaml
  echo -e "${GREEN}Rate limiter up and running!${NC}"
  
  echo -e "${GREEN}Infrastructure setup complete! (Step 1)${NC}"
  echo -e "${YELLOW}To deploy the application, run: $0 --step 2${NC}"
fi

# Step 2: Application deployment
if [[ "$STEP" == "2" ]]; then
  echo -e "${BLUE}[STEP 2] Deploying application...${NC}"

  echo -e "${BLUE}[1/2]${NC} Deploying the application..."
  # For Helm deployment, we'll use 'localhost' as the host for the Istio gateway.
  # The actual access IP will be determined in Step 2 after 'minikube tunnel' is running.

    # Try to get external IP from LoadBalancer status first, then from NodePort if that fails
    EXTERNAL_IP_RAW=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

    # If external IP is empty, fall back to node IP + nodePort
    if [ -z "$EXTERNAL_IP_RAW" ]; then
        # Show an error message
        echo -e "${RED}No external IP found for istio-ingressgateway. Run 'minikube tunnel' in a separate terminal first.${NC}"
        exit 1
    fi

  EXTERNAL_IP="${EXTERNAL_IP_RAW%\%}" # Remove trailing % if present

  echo -e "${YELLOW}Using '$EXTERNAL_IP' for istio.ingressGateway.host in Helm chart.${NC}"
  helm install my-sentiment-analysis ./kubernetes/helm/sentiment-analysis --set istio.ingressGateway.host=$EXTERNAL_IP
  echo -e "${GREEN}Application deployed!${NC}"

  echo -e "${BLUE}[2/2]${NC} Waiting for pods to be ready..."
  kubectl wait --for=condition=ready pod --all --timeout=300s || true
  echo -e "${GREEN}Pod readiness check complete.${NC}"

  echo -e "${BLUE}Waiting a few seconds for network routes to establish...${NC}"
  sleep 5

  if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" == "<pending>" ] || [ "$EXTERNAL_IP" == "pending" ]; then
      echo -e "${RED}Could not determine external IP for istio-ingressgateway.${NC}"
      echo -e "${YELLOW}This usually means 'sudo minikube tunnel' is not running or not working correctly.${NC}"
      echo -e "${YELLOW}Please run minikube tunnel and try again.${NC}"
      exit 1
  else
      echo -e "${GREEN}Successfully retrieved External IP: $EXTERNAL_IP${NC}"
  fi

  echo
  echo -e "${GREEN}===========================${NC}"
  echo -e "${GREEN}Access Your Services:${NC}"
  echo -e "${YELLOW}1. Run ${NC}minikube tunnel${YELLOW} in a separate terminal${NC}"
  echo -e "${YELLOW}2. Application URL:${NC} http://$EXTERNAL_IP"
  echo
  echo -e "${YELLOW}To access dashboards, run these commands in separate terminals:${NC}"
  echo -e "${YELLOW}1. Prometheus Dashboard:${NC} kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090"
  echo -e "${YELLOW}2. Grafana Dashboard:${NC} kubectl -n monitoring port-forward service/prometheus-grafana 3300:80"
  echo -e "${YELLOW}3. Kiali Dashboard:${NC} kubectl -n istio-system port-forward svc/kiali 20001:20001"
  echo
  echo -e "${GREEN}===========================${NC}"
fi
echo -e "${GREEN}Script finished.${NC}"
