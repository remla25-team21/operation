#!/bin/bash

set -e  # Exit on error

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}===== Minikube Setup Script for Sentiment Analysis App =====${NC}"

# Argument parsing
if [ "$#" -ne 2 ] || [ "$1" != "--step" ]; then
  echo -e "${RED}Usage: $0 --step <1|2>${NC}"
  echo -e "${YELLOW}  --step 1: Initial setup (Minikube, Istio, Prometheus, App deployment).${NC}"
  echo -e "${YELLOW}            You will be prompted to run 'sudo minikube tunnel' manually after this step.${NC}"
  echo -e "${YELLOW}  --step 2: Display access URLs (run after 'sudo minikube tunnel' is active).${NC}"
  exit 1
fi

STEP=$2

if [ "$STEP" == "1" ]; then
  echo -e "${BLUE}Executing Step 1: Initial Setup...${NC}"
  echo

  # Check if necessary tools are installed
  for tool in minikube kubectl helm istioctl; do
    if ! command -v $tool &> /dev/null; then
      echo -e "${RED}Error: $tool is not installed. Please install it first.${NC}"
      exit 1
    fi
  done
  echo -e "${GREEN}All necessary tools are installed.${NC}"

  echo -e "${BLUE}[1/6]${NC} Cleaning up any existing Minikube clusters..."
  minikube delete --all > /dev/null 2>&1 || true

  echo -e "${BLUE}[2/6]${NC} Starting Minikube..."
  minikube start --memory=4096 --cpus=4 --driver=docker
  minikube addons enable ingress
  echo -e "${GREEN}Minikube started successfully!${NC}"

  echo -e "${BLUE}[3/6]${NC} Installing Prometheus stack..."
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts > /dev/null 2>&1
  helm repo update > /dev/null 2>&1
  helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
  echo -e "${GREEN}Prometheus stack installed!${NC}"

  echo -e "${BLUE}[4/6]${NC} Installing Istio and its add-ons..."
  istioctl install -y
  kubectl apply -f kubernetes/istio-addons/prometheus.yaml
  kubectl apply -f kubernetes/istio-addons/jaeger.yaml
  kubectl apply -f kubernetes/istio-addons/kiali.yaml
  kubectl label ns default istio-injection=enabled --overwrite
  echo -e "${GREEN}Istio installed!${NC}"

  echo -e "${BLUE}[5/6]${NC} Deploying the application..."
  # For Helm deployment, we'll use 'localhost' as the host for the Istio gateway.
  # The actual access IP will be determined in Step 2 after 'minikube tunnel' is running.
  GATEWAY_IP_FOR_HELM_VALUES="localhost"
  echo -e "${YELLOW}Using '$GATEWAY_IP_FOR_HELM_VALUES' for istio.ingressGateway.host in Helm chart.${NC}"
  helm install my-sentiment-analysis ./kubernetes/helm/sentiment-analysis --set istio.ingressGateway.host=$GATEWAY_IP_FOR_HELM_VALUES
  echo -e "${GREEN}Application deployed!${NC}"

  echo -e "${BLUE}[6/6]${NC} Waiting for pods to be ready..."
  kubectl wait --for=condition=ready pod --all --timeout=300s || true
  echo -e "${GREEN}Pod readiness check complete.${NC}"

  echo
  echo -e "${GREEN}======================================================${NC}"
  echo -e "${GREEN}Step 1 Completed Successfully!${NC}"
  echo -e "${YELLOW}Next Steps:${NC}"
  echo -e "${YELLOW}1. Open a NEW terminal window.${NC}"
  echo -e "${YELLOW}2. Run the following command in the new terminal (it requires root privileges and will run in the foreground):${NC}"
  echo -e "   ${GREEN}sudo minikube tunnel${NC}"
  echo -e "${YELLOW}3. Keep the 'minikube tunnel' command running.${NC}"
  echo -e "${YELLOW}4. Once the tunnel is active, run the following command to get access URLs:${NC}"
  echo -e "   ${GREEN}$0 --step 2${NC}"
  echo -e "${GREEN}======================================================${NC}"

elif [ "$STEP" == "2" ]; then
  echo -e "${BLUE}Executing Step 2: Displaying Access Information...${NC}"
  echo -e "${YELLOW}Ensure 'sudo minikube tunnel' is running in another terminal.${NC}"
  echo

  echo -e "${BLUE}Waiting a few seconds for network routes to establish...${NC}"
  sleep 5

  EXTERNAL_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

  if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" == "<pending>" ] || [ "$EXTERNAL_IP" == "pending" ]; then
      echo -e "${RED}Could not determine external IP for istio-ingressgateway.${NC}"
      echo -e "${YELLOW}This usually means 'sudo minikube tunnel' is not running or not working correctly.${NC}"
      echo -e "${YELLOW}Attempting to use 'localhost'. If this doesn't work, please verify your 'minikube tunnel' setup.${NC}"
      EXTERNAL_IP="localhost"
  else
      echo -e "${GREEN}Successfully retrieved External IP: $EXTERNAL_IP${NC}"
  fi

  echo
  echo -e "${GREEN}===========================${NC}"
  echo -e "${GREEN}Access Your Services:${NC}"
  echo -e "${YELLOW}Application URL:${NC} http://$EXTERNAL_IP"
  echo
  echo -e "${YELLOW}To access dashboards, run these commands in separate terminals:${NC}"
  echo -e "${YELLOW}Prometheus Dashboard:${NC} kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090"
  echo -e "${YELLOW}Grafana Dashboard:${NC}    kubectl -n monitoring port-forward service/prometheus-grafana 3300:80"
  echo -e "${YELLOW}Kiali Dashboard:${NC}      kubectl -n istio-system port-forward svc/kiali 20001:20001"
  echo
  echo -e "${YELLOW}Important:${NC}"
  echo -e "${YELLOW}- The 'sudo minikube tunnel' command must remain running in its terminal to access the Application URL.${NC}"
  echo -e "${YELLOW}- To stop access, close the 'minikube tunnel' terminal or press Ctrl+C in it.${NC}"
  echo -e "${GREEN}===========================${NC}"

else
  echo -e "${RED}Invalid step: '$STEP'. Please use --step 1 or --step 2.${NC}"
  echo -e "${RED}Usage: $0 --step <1|2>${NC}"
  exit 1
fi

echo -e "${GREEN}Script finished.${NC}"
