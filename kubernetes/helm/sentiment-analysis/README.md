# Sentiment Analysis Helm Chart

This Helm chart deploys the Restaurant Review Sentiment Analysis application, which includes a model service for sentiment analysis and a web application frontend/backend.

> [!NOTE]
> TL;DR:
>
> 1. Run the following command to install the chart and access the application:
>
> ```bash
> helm install my-sentiment-analysis ./kubernetes/helm/sentiment-analysis
> kubectl port-forward svc/my-sentiment-analysis-app-frontend 3000:3000  # Keep this running in a separate terminal
> kubectl port-forward svc/my-sentiment-analysis-app-service 5000:5000  # Keep this running in another terminal
> ```
>
> 2. Start prometheus and Grafana to monitor the application:
>
> ```bash
> helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
> helm repo update
> helm install prometheus prometheus-community/kube-prometheus-stack
> kubectl port-forward svc/prometheus-operated 9090:9090  # Keep this running in a separate terminal
> ```
>
> 3. Access the application at `http://localhost:3000` and Prometheus at `http://localhost:9090`.
> 4. For Grafana, ...

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
   kubectl port-forward svc/my-sentiment-analysis-app-frontend 3000:3000
   ```
6. You also have to port-forward the backend service for it to be reachable from the frontend accessed via localhost
   ```bash
   kubectl port-forward svc/my-sentiment-analysis-app-service 5000:5000
   ```
7. Access the application from `http://localhost:3000`.

## Prometheus Monitoring

The app-service includes built-in Prometheus metrics to monitor application usage and performance. A ServiceMonitor resource is deployed alongside the application to enable automatic metrics scraping by Prometheus.

### Available Metrics

1. **sentiment_predictions_total** (Counter)
   - Tracks the total number of sentiment predictions made
   - Includes labels to differentiate between positive and negative sentiments
   
2. **sentiment_positive_ratio** (Gauge)
   - Measures the ratio of positive to total sentiments (value between 0-1)
   
3. **sentiment_prediction_latency_seconds** (Histogram)
   - Tracks the time taken to process sentiment predictions
   - Includes multiple buckets to categorize response times
   
### Accessing Metrics

You can access the metrics directly by port-forwarding the app-service and visiting the metrics endpoint:

```bash
kubectl port-forward service/app-service 5000:5000
```

Then visit `http://localhost:5000/metrics` in your browser.

### Setting Up Prometheus

1. Make sure you have the Prometheus Operator installed in your cluster. If you don't have it installed, you can use the kube-prometheus-stack Helm chart:

   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   helm install prometheus prometheus-community/kube-prometheus-stack
   ```

2. The ServiceMonitor included in this chart is configured to be automatically discovered by Prometheus, as long as your Prometheus instance is configured to discover ServiceMonitors in this namespace.

3. You can check if the ServiceMonitor is working by running:

   ```bash
   kubectl get servicemonitors
   ```

4. To access the Prometheus dashboard, you can port-forward the Prometheus service:

   ```bash
   kubectl port-forward svc/prometheus-operated 9090:9090
   ```

   Then visit `http://localhost:9090` in your browser and query for the metrics like:
   - `sentiment_predictions_total`
   - `sentiment_positive_ratio`
   - `sentiment_prediction_latency_seconds_bucket`

### Grafana Dashboard

// TODO
