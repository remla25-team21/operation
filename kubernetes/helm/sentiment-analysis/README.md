# Sentiment Analysis Helm Chart

This Helm chart deploys the Restaurant Review Sentiment Analysis application, which includes a model service for sentiment analysis and a web application frontend/backend.

> [!NOTE]
> TL;DR:
>
> 1. Run the following command to install the chart and access the application:
>
> ```bash
> helm install my-sentiment-analysis ./kubernetes/helm/sentiment-analysis
> ```
>
> ```bash
>  # Keep this running in a separate terminal
> kubectl port-forward svc/app-frontend 3000:3000
> ```
>
> ```bash
>  # Keep this running in another terminal
> kubectl port-forward service/app-service 5000:5000
> ```
>
> 2. Start prometheus and Grafana to monitor the application:
>
> ```bash
> helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
> helm repo update
> helm install prometheus prometheus-community/kube-prometheus-stack
> ```
>
> ```bash
>  # Keep this running in a separate terminal
> kubectl port-forward service/prometheus-operated 9090:9090
> ```
>
> 3. Access the application at [http://localhost:3000](http://localhost:3000) and Prometheus at [http://localhost:9090](http://localhost:9090).
> 4. For Grafana, port-forward it on a different port (e.g., 3300) and open [http://localhost:3300](http://localhost:3300). Log in with `admin / prom-operator` and open the pre-provisioned "Dashboard" under **Dashboards -> Browse**. 
> ```bash
>  # Keep this running in a separate terminal
> kubectl port-forward service/prometheus-grafana 3300:80
> ```

## Installation

1. First, ensure you have your Kubernetes cluster running (e.g., with `minikube start`)
2. Make sure that you are inside of the `sentiment-analysis` folder.
3. Install the chart:
   ```bash
   helm install my-sentiment-analysis .
   ```
4. You can check if you've successfully installed your Helm release. (e.g., `helm status my-sentiment-analysis` to check the status of release, `kubectl get pods` to check that the pods are running, `kubectl get svc` to check for services, `kubectl get ingress` to check for ingress etc)
5. You can port-forward the frontend service to your local machine like this:
   ```bash
   kubectl port-forward svc/app-frontend 3000:3000
   ```
6. You also have to port-forward the backend service for it to be reachable from the frontend accessed via localhost
   ```bash
   kubectl port-forward service/app-service 5000:5000
   ```
7. Access the application from `http://localhost:3000`.
