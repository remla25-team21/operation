# Sentiment Analysis Helm Chart

This Helm chart deploys the Restaurant Review Sentiment Analysis application, which includes a model service for sentiment analysis and a web application frontend/backend.

> [!NOTE]
> TL;DR:
>
> 1. Make sure your Kubernetes cluster is running (e.g., `minikube start`). 
>
> 2. Add the Prometheus Helm chart repository and install the Prometheus + Grafana stack. 
>
> ```bash
> helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
> helm repo update
> helm install prometheus prometheus-community/kube-prometheus-stack
> ```
>
> After installing the Prometheus stack, it may take some time for all pods to become ready. You can monitor the status using `kubectl get pods` to ensure they are running before proceeding. 
>
> ```bash
>  # Keep this running in a separate terminal
> kubectl -n default port-forward svc/prometheus-kube-prometheus-prometheus 9090
> ```
>
> ```bash
>  # Keep this running in a separate terminal
> kubectl port-forward service/prometheus-grafana 3300:80
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
> kubectl port-forward svc/my-sentiment-analysis-app-frontend 3000:3000
> ```
>
> ```bash
>  # Keep this running in another terminal
> kubectl port-forward svc/my-sentiment-analysis-app-service 5000:5000
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
      kubectl port-forward svc/my-sentiment-analysis-app-frontend 3000:3000
      ```
   - Backend: 
      ```bash
      kubectl port-forward svc/my-sentiment-analysis-app-service 5000:5000
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

4. **model_usage_total** (Counter)
   - Tracks the number of times the prediction model is used
   - Essential for measuring feature adoption and comparing variant performance

5. **user_session_duration_seconds** (Histogram)
   - Measures the duration of user sessions in seconds
   - Useful for understanding user engagement patterns

6. **user_star_ratings** (Histogram)
   - Tracks the distribution of user star ratings (1-5 scale)
   - Provides insights into customer satisfaction levels across different restaurants

### Accessing Metrics

You can access the metrics directly by port-forwarding the app-service and visiting the metrics endpoint:

```bash
kubectl port-forward svc/my-sentiment-analysis-app-service 5000:5000
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
   kubectl -n default port-forward svc/prometheus-kube-prometheus-prometheus 9090
   ```

   Then visit [`http://localhost:9090`](http://localhost:9090) in your browser and query for the metrics like:
   - `sentiment_predictions_total`
   - `sentiment_positive_ratio`
   - `sentiment_prediction_latency_seconds_bucket`
   - `model_usage_total`
   - `user_session_duration_seconds_bucket`
   - `user_star_ratings_bucket`

## Alerting

We implemented a `PrometheusRule` resource in the Helm chart that defines an alert called `HighSentimentPredictionRate`. This alert triggers if the rate of sentiment predictions exceeds 10 requests per minute continuously for one minute. It includes severity labels and detailed annotations such as a summary, a description referencing the app service name, and a runbook URL for troubleshooting.

To test this alert, send more than 10 requests to the model within a minute and wait for the alert to activate.

You can access the Alertmanager dashboard to view and manage alerts by running:

```bash
kubectl port-forward svc/alertmanager-operated 9093 -n default
```

It can also be found under Alert tab in Prometheus dashboard.

### Grafana Dashboard
Grafana is used to visualize the Prometheus metrics collected from the `app-service`. A custom dashboard is automatically provisioned during deployment using a `ConfigMap`.

#### Dashboard Features
The Grafana dashboard includes:

* Total Sentiment Predictions: A timeseries chart based on `sentiment_predictions_total`, with separate lines for each sentiment class. 
* Positive Sentiment Ratio: A gauge showing the real-time ratio of positive reviews (`sentiment_positive_ratio`), ranging from 0 (all negative) to 1 (all positive). 
* Prediction Latency (50th Percentile): A line graph showing the median request latency using
  `histogram_quantile(0.5, rate(sentiment_prediction_latency_seconds_bucket[5m]))`. 
* Model Usage Tracking: A counter visualizing model usage frequency (`model_usage_total`) across different experimental variants to support A/B testing.
* User Session Duration: A histogram displaying user engagement patterns (`user_session_duration_seconds`) to measure the effectiveness of different UI/UX designs.
* User star ratings: A histogram visualizing user satisfaction ratings (`user_star_ratings`) to identify trends in customer feedback.

#### Automatic Provisioning
No manual import is required. The dashboard is automatically loaded by Grafana using a Kubernetes ConfigMap (`sentiment-dashboard`) defined in the Helm chart. 

#### Accessing Grafana

1. Port-forward the Grafana service on a free port (e.g., `3300`):

   ```bash
   kubectl port-forward service/prometheus-grafana 3300:80
   ```

2. Open Grafana in your browser: [`http://localhost:3300`](http://localhost:3300)

3. Log in with: 
   * **Username:** `admin` 
   * **Password:** `prom-operator` (default) 

4. Navigate to **Dashboards -> Browse** and open the dashboard titled "Dashboard".
