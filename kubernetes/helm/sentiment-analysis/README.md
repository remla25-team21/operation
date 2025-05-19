# Sentiment Analysis Helm Chart

This Helm chart deploys the Restaurant Review Sentiment Analysis application, which includes a model service for sentiment analysis and a web application frontend/backend.

> [!NOTE]
> TL;DR:
>
> 1. Make sure your Kubernetes cluster is running (e.g., `minikube start`). 
>
> 2. Add the Prometheus Helm chart repository and install the Prometheus + Grafana stack: 
>
> ```bash
> helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
> helm repo update
> helm install prometheus prometheus-community/kube-prometheus-stack
> ```
>
> ```bash
>  # Keep this running in a separate terminal
> kubectl port-forward svc/prometheus-operated 9090:9090
> ```
>
> ```bash
>  # Keep this running in a separate terminal
> kubectl port-forward scv/prometheus-grafana 3300:80
> ```
>
> 3. Deploy the sentiment analysis application:
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
> 4. Access the interfaces:
> - Application: [`http://localhost:3000`](http://localhost:3000) 
> - Prometheus: [`http://localhost:9090`](http://localhost:9090)
> - Grafana: [`http://localhost:3300`](http://localhost:3300) 
>
> 5. In Grafana, log in with `admin / prom-operator`. Go to **Dashboards -> Browse** and open the pre-provisioned dashboard titled "Dashboard". 

## Installation

1. Start a Kubernetes cluster locally using Minikube (or your preferred provider): 
   ```bash
   minikube start
   ```

2. Before deploying the application, install the monitoring stack so that Prometheus can discover metrics and Grafana can auto-load dashboards: 
   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   helm install prometheus prometheus-community/kube-prometheus-stack -n default
   ```

3. Deploy the sentiment analysis application: 
   ```bash
   helm install my-sentiment-analysis ./kubernetes/helm/sentiment-analysis -n default
   ```

4. You can verify the deployment by checking the status of your Helm release and inspecting the running Kubernetes resources. For example: 
   - `helm status my-sentiment-analysis`: shows the release status and resources created 
   - `kubectl get pods`: confirms that all application pods are running 
   - `kubectl get svc`: lists the exposed services 
   - `kubectl get ingress` shows ingress configurations if used 

5.  Port-forward services (in separate terminals): 
   - Frontend: 
      ```bash
      kubectl port-forward svc/app-frontend 3000:3000
      ```
   - Backend: 
      ```bash
      kubectl port-forward svc/app-service 5000:5000 -n default
      ```

6.  Access the application from [`http://localhost:3000`](http://localhost:3000).

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

Then visit [`http://localhost:5000/metrics`](http://localhost:5000/metrics) in your browser.

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

   Then visit [`http://localhost:9090`](http://localhost:9090) in your browser and query for the metrics like:
   - `sentiment_predictions_total`
   - `sentiment_positive_ratio`
   - `sentiment_prediction_latency_seconds_bucket`

### Grafana Dashboard
Grafana is used to visualize the Prometheus metrics collected from the `app-service`. A custom dashboard is automatically provisioned during deployment using a `ConfigMap`.

#### Dashboard Features
The Grafana dashboard includes:

* Total Sentiment Predictions: A timeseries chart based on `sentiment_predictions_total`, with separate lines for each sentiment class. 
* Positive Sentiment Ratio: A gauge showing the real-time ratio of positive reviews (`sentiment_positive_ratio`), ranging from 0 (all negative) to 1 (all positive). 
* Prediction Latency (50th Percentile): A line graph showing the median request latency using
  `histogram_quantile(0.5, rate(sentiment_prediction_latency_seconds_bucket[5m]))`. 

#### Automatic Provisioning
No manual import is required. The dashboard is automatically loaded by Grafana using a Kubernetes ConfigMap (`sentiment-dashboard`) defined in the Helm chart. 

#### Accessing Grafana

1. Port-forward the Grafana service on a free port (e.g., `3300`):

   ```bash
   kubectl port-forward service/prometheus-grafana 3300:80
   ```

2. Open Grafana in your browser: [`http://local`host:3300`](http://localhost:3300)

3. Log in with: 
   * **Username:** `admin` 
   * **Password:** `prom-operator` (default) 

4. Navigate to **Dashboards -> Browse** and open the dashboard titled "Dashboard". 
