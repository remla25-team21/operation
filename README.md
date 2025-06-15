# Operation Repository

This is the central repository for a REMLA project by Group 21. The application performs sentiment analysis on user feedback using a machine learning model. This repository orchestrates the following components hosted in separate repositories:

- [`model-training`](https://github.com/remla25-team21/model-training): Contains the machine learning training pipeline.
- [`lib-ml`](https://github.com/remla25-team21/lib-ml): Contains data pre-processing logic used across components.
- [`model-service`](https://github.com/remla25-team21/model-service): A wrapper service for the trained ML model. Exposes API endpoints to interact with the model.
- [`lib-version`](https://github.com/remla25-team21/lib-version): A version-aware utility library that exposes version metadata.
- [`app`](https://github.com/remla25-team21/app): Contains the application frontend and backend (user interface and service logic). 

## Table of Contents 

- [How to Start the Application (Assignment 1)](#how-to-start-the-application-assignment-1)
- [Kubernetes Cluster Provisioning (Assignment 2)](#kubernetes-cluster-provisioning-assignment-2)
- [Kubernetes Cluster Monitoring (Assignment 3)](#kubernetes-cluster-monitoring-assignment-3)
- [ML Configuration Management \& ML Testing （Assignment 4）](#ml-configuration-management--ml-testing-assignment-4)
- [Istio Service Mesh（Assignment 5）](#istio-service-meshassignment-5)
   - [Method 1: Using Vagrant/Ansible Cluster](#method-1-using-vagrantansible-cluster)
      - [Deploy the Istio-based Setup](#deploy-the-istio-based-setup)
      - [Verify Sticky Sessions](#verify-sticky-sessions)
   - [Method 2: Using Local Minikube](#method-2-using-local-minikube)
      - [Quick Start with Automated Script](#quick-start-with-automated-script)
      - [Manual Setup and Deploy](#manual-setup-and-deploy)
      - [Verify Sticky Sessions](#verify-sticky-sessions-1)
   - [Continuous Experimentation](#continuous-experimentation)
   - [Additional Use Case: Rate Limiting](#additional-use-case)
- [Known Issue: macOS Port Conflict (AirPlay Receiver)](#known-issue-macos-port-conflict-airplay-receiver)
- [Activity Tracking](#activity-tracking)

## How to Start the Application (Assignment 1)

1. Clone the repository:

   ```bash
   git clone https://github.com/remla25-team21/operation.git
   ```

2. Navigate into the project directory and start the app with Docker Compose:

   ```bash
   cd kubernetes
   docker-compose pull && docker-compose up -d
   ```

The frontend will be available at [`http://localhost:3000`](http://localhost:3000) by default.

## Kubernetes Cluster Provisioning (Assignment 2)

These steps guide you through setting up the Kubernetes cluster on your local machine using Vagrant and Ansible, and deploying the Kubernetes Dashboard.

1. Install GNU parallel:
   Before running the setup script, make sure GNU parallel is installed on your system:
   - For Debian/Ubuntu:

      ```bash
      sudo apt-get install parallel
      ```

   - For Red Hat/CentOS:

      ```bash
      sudo yum install parallel
      ```

   - For macOS:

      ```bash
      brew install parallel
      ```

2. Run the setup script:

   ```bash
   chmod +x setup_cluster.sh
   ./setup_cluster.sh
   ```

3. Access Kubernetes sashboard:
   - After the script completes, open your web browser and navigate to: [`https://dashboard.local`](https://dashboard.local) (**HTTPS** is required).
   - You will see a token displayed in your terminal. Copy and paste this token into the Kubernetes Dashboard login page.
4. Remove the cluster:
   If you want to remove the cluster, run the following command:

   ```bash
   vagrant destroy -f
   ```

   This will remove all the VMs and the Kubernetes cluster.

## Kubernetes Cluster Monitoring (Assignment 3)

Refer to [README.md](./kubernetes/helm/sentiment-analysis/README.md) in the `kubernetes/helm/sentiment-analysis` directory for instructions to set up Prometheus and Grafana for monitoring.

## ML Configuration Management & ML Testing （Assignment 4）

Work for Assignment 4 is mainly in the following repositories:

- [`model-training`](https://github.com/remla25-team21/model-training)
- [`model-service`](https://github.com/remla25-team21/model-service)

See their READMEs for setup and testing details.

## Istio Service Mesh（Assignment 5）

Two methods are available for deploying the application with Istio service mesh:

- [Method 1](#method-1-using-vagrantansible-cluster): Using Vagrant/Ansible Cluster from Assignment 2
- [Method 2](#method-2-using-local-minikube): Using Local Minikube

### Method 1: Using Vagrant/Ansible Cluster

Run the following command to start up the local Kubernetes cluster. (Make sure that you have GNU Parallel installed. Details in [Section 2](#kubernetes-cluster-provisioning-assignment-2). )

#### Deploy the Istio-based Setup

1. Start the local cluster:

   ```bash
   chmod +x setup_cluster.sh
   ./setup_cluster.sh
   ```

2. SSH into the control node:  

   ```bash
   vagrant ssh ctrl
   ```

3. Deploy the application using Helm:

   ```bash
   cd /vagrant
   GATEWAY_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   helm install my-sentiment-analysis ./kubernetes/helm/sentiment-analysis --set istio.ingressGateway.host=$GATEWAY_IP
   ```

   > [!NOTE]
   > It may take a few minutes for all pods to become ready.
   > You can monitor the status with:
   >
   > ```bash
   > kubectl get pods
   > ```

4. Access the frontend from [`http://192.168.56.91`](http://192.168.56.91).

#### Verify Sticky Sessions

Sticky routing is enabled in `DestinationRule`. You can use `curl` to simulate multiple users:

```bash
for i in {1..5}; do curl -s -H "user: 6" http://192.168.56.91/env-config.js; done
for i in {1..5}; do curl -s -H "user: 10" http://192.168.56.91/env-config.js; done
```

Users `6` and `10` should always see the same version on each reload.

### Method 2: Using Local Minikube

This alternative approach uses Minikube directly on your local machine without Vagrant/Ansible.

#### Quick Start with Automated Script

We provide an automated script that handles the entire setup process:

```bash
chmod +x start_minikube.sh
./start_minikube.sh --step 1

minikube tunnel  # Keep this running in a separate terminal

./start_minikube.sh --step 2
```

> [!NOTE]
>
> Please refer to the [Manual Setup and Deploy](#manual-setup-and-deploy) section below if you encounter any issues with the script or prefer to run commands individually.

This script will:

- Delete any existing Minikube clusters
- Start Minikube with appropriate resources
- Install Prometheus stack
- Install Istio and its add-ons
- Deploy the application
- Start the Minikube tunnel
- Display access URLs for all services

The script will output instructions for accessing all components when it completes.

#### Manual Setup and Deploy

If you prefer to run commands individually:

1. Clean up any existing Minikube clusters:

   ```bash
   minikube delete --all 
   ```

2. Start and configure Minikube:

   ```bash
   minikube start  --memory=4096 --cpus=4 --driver=docker
   minikube addons enable ingress
   ```

   > Note: Resource requirements (4GB RAM, 4 CPUs) can be adjusted based on your machine's capabilities.

3. Install Prometheus stack using Helm:

   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
   ```

4. Install Istio and its add-ons:

   ```bash
   istioctl install -y
   kubectl apply -f kubernetes/istio-addons/prometheus.yaml
   kubectl apply -f kubernetes/istio-addons/jaeger.yaml
   kubectl apply -f kubernetes/istio-addons/kiali.yaml
   kubectl label ns default istio-injection=enabled --overwrite
   ```

5. Open the tunnel for Istio ingress gateway:

   ```bash
   minikube tunnel  # Keep this running in a `separate` terminal
   ```

6. Deploy the application using Helm:

   ```bash
   GATEWAY_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

   helm install my-sentiment-analysis ./kubernetes/helm/sentiment-analysis --set istio.ingressGateway.host=$GATEWAY_IP
   ```

7. Forward necessary ports in separate terminals:

   ```bash
   kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090
   kubectl -n monitoring port-forward service/prometheus-grafana 3300:80
   kubectl -n istio-system port-forward svc/kiali 20001:20001
   ```

   > Note: Keep these commands running in separate terminals.

8. Access different interfaces:

   ```bash
   kubectl get svc istio-ingressgateway -n istio-system
   ```

   - Application: Access the url output by `kubectl get svc istio-ingressgateway -n istio-system` as [EXTERNAL-IP].
   - Prometheus: [`http://localhost:9090`](http://localhost:9090)
   - Grafana: [`http://localhost:3300`](http://localhost:3300)
   - Kiali: [`http://localhost:20001`](http://localhost:20001)

#### Verify Sticky Sessions

For this setup, test sticky sessions with:

```bash
for i in {1..5}; do curl -s -H "user: 6" http://[EXTERNAL-IP]/env-config.js; done
for i in {1..5}; do curl -s -H "user: 10" http://[EXTERNAL-IP]/env-config.js; done
```
### Continuous Experimentation 

We used Istio’s traffic routing to run an A/B test between two frontend versions. Prometheus collected usage and satisfaction metrics, and the outcome was visualized in Grafana. Details are in [`docs/continuous-experimentation.md`](https://github.com/remla25-team21/operation/blob/main/docs/continuous-experimentation.md). 

### Additional Use Case: Rate Limiting 

To protect the application from abuse and ensure fair usage across users, we implemented rate limiting using an Istio `EnvoyFilter`. This configuration limits each unique `x-user-id` header to 10 requests per minute on the inbound sidecar. 

We used two `EnvoyFilter` resources:
   - The first inserts the `envoy.filters.http.local_ratelimit` filter into the inbound HTTP filter chain. It defines a token bucket allowing 10 requests every 60 seconds per user.
   - The second configures route-level rate limits by matching the `x-user-id` header and enforcing the per-user descriptor.

The response will include a custom header `x-local-rate-limit: true` when rate limiting is triggered. You can verify the rate limit by sending more than 10 requests within a minute. 

## Known Issue: macOS Port Conflict (AirPlay Receiver)

If `app-service` fails to bind to port 5000, macOS's AirPlay Receiver may be using it.

**Temporary Workaround**

1. Go to System Settings -> General -> Airdrop & Handoff and switch off Airplay Receiver.
2. Go to terminal and use kill any process on port 5000:
   ```bash
   lsof -i :5000
   kill -9 <PID>
   ```

**Long Term Fix**

We plan to eventually change `app-service` to accomodate environment variables which should allow users to freely change ports via `docker-compose.yml` file.

## Activity Tracking

See in [ACTIVITY.md](https://github.com/remla25-team21/operation/blob/main/ACTIVITY.md) for an overview of team contributions. 
