# Continuous Experimentation: A/B Testing Visual Design Impact on User Engagement 

## Experiment Overview 
As part of our release engineering pipeline, we used Continuous Experimentation (CE) to evaluate whether a simple UI change (background and button color) could influence user behavior and satisfaction in our sentiment-based restaurant review application. The experiment is deployed using Istio's dynamic traffic routing and monitored via Prometheus and Grafana. It demonstrates how CE can guide product decisions using real-time observability, even for minor feature tweaks. 

## Implemented Changes 

The following changes were implemented between version `v1` (control) and `v2` (treatment):

### Frontend 
- `v2` only differs visually from `v1`: a new color scheme for background and buttons via `styles.css`. 
- Common features in both versions:
  - Displayed the version (`v1` or `v2`) in the top-right corner. 
  - Replaced the prior feedback system with a 1–5 star rating component after prediction. 

### Backend 
- Added two Prometheus metrics exposed at `/metrics`: 
  - `model_usage_total` (Counter): Counts model usage per app version. This is essential for measuring feature adoption and comparing variant performance. 
  - `user_star_ratings` (Histogram): Captures post-review user satisfaction on a 1–5 scale. This provides insights into customer satisfaction levels across different restaurants. 
- All requests are version-tagged via the `app-version` HTTP header. 
- Endpoints:
  - `/predict`: Returns sentiment prediction. 
  - `/submit-rating`: Receives post-review ratings. 

## Hypothesis 
- Null Hypothesis ($H_0$): The visual change does not significantly impact user engagement or satisfaction.  
- Alternative Hypothesis ($H_1$): Users exposed to `v2` (new buttons and background color) will: 
  - use the prediction feature more frequently, 
  - and/or give higher satisfaction ratings. 

## Metrics 
Prometheus scrapes and aggregates the following metrics: 
  - `model_usage_total`: The number of predictions. 
  - `user_star_ratings`: Satisfaction score distribution. 

### Prometheus Configuration 
Metric scraping is enabled using pod annotations:
```yaml
    annotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: "/metrics"
        prometheus.io/port: "8080"
```

## Experiment Setup 

### Deployment Details 
- Two versions (`v1` and `v2`) are deployed in parallel as separate Kubernetes deployments. 
- Istio Gateway and VirtualService are both exposed via IngressGateway. 
- DestinationRules define subsets for `v1` and `v2`. 
- Canary routing (50/50 split) is enforced with sticky sessions using the `user` header. 
- Consistent backend–frontend versioning ensured by matching routing headers. 

> [!NOTE]
> In the production setup, the app service uses a 90/10 routing strategy. The 50/50 split is applied only during this experiment to ensure fair comparison of model usage between versions. 

### Request Routing Flow 
User Request -> Istio’s Ingress Gateway -> VirtualService -> DestinationRule (`v1`/`v2` subset) -> versioned app pods. 

### Instructions to Reproduce  
1. Deploy the system as described in Section "Method 1: Using Vagrant/Ansible Cluster" of [`READM.md`](https://github.com/remla25-team21/operation/blob/main/README.md). 
2. Port-forward Prometheus in a separate terminal of the `ctrl` node: 
   ```bash
   kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090
   ```
3. Port-forward Grafana in a separate terminal of the `ctrl` node: 
   ```bash
   kubectl -n monitoring port-forward svc/prometheus-grafana 3300:80
   ```
4. Run the following commands on your host machine: 
   ```bash
   vagrant ssh ctrl -- -L 9090:localhost:9090 -L 3300:localhost:3300
   ```
5. The dashboard JSON is available in [`kubernetes/helm/sentiment-analysis/grafana/grafana-ce-dashboard.json`](https://github.com/remla25-team21/operation/blob/main/kubernetes/helm/sentiment-analysis/grafana/grafana-ce-dashboard.json). To import the dashboard: 
   1. Visit Grafana at [`http://localhost:3300`](http://localhost:3300) 
   2. Log in with `admin / prom-operator`. 
   3. Navigate to Dashboards -> + -> Import aashoboard -> Upload dashboed JSON file -> Import. 
   4. You can then check the dashboard titled "CE - UI Variant A/B Test". 
6. Simulate user traffic. 

## Grafana Dashboard 
The dashboard titled "CE - UI Variant A/B Test" includes: 
  - `sum by (container) (model_usage_total)`; Aggregates prediction usage by version 
  - `histogram_quantile(0.5, rate(user_star_ratings_bucket[30m]))`: Computes median rating per version 

### Screenshot 
The following screenshot shows the Grafana dashboard, which compares model usage and satisfaction metrics for both frontend versions. 
![Dashboard Screenshot](https://github.com/remla25-team21/operation/blob/main/pics/grafana-dashboard-ce.png) 

## Decision Process 
A version is considered successful and eligible for full rollout only if both conditions hold during a 30-minute observation window: 
  - **Model Usage**: `model_usage_total` for `v2` is ≥10% higher than `v1`. 
  - **User Satisfaction**: Median of `user_star_ratings` for `v2` is not lower than for `v1`. 

If either condition fails, `v2` will not be promoted and the UI design change will be reevaluated or rolled back. 

## Results (Observed on: 2025-06-02)

Prometheus successfully collected version-tagged metrics, and the Grafana dashboard displayed the following: 
  - **Model Usage**: `v2` received 11.32% fewer prediction requests than `v1`. 
  - **User Satisfaction**: Both versions maintained a median score of 4.4-4.5 out of 5. 

### Conclusion 
The hypothesis was not supported. While the UI modification in `v2` maintained user satisfaction, it resulted in a noticeable decline in user engagement (11.32% less usage). Therefore, we recommend retaining `v1` as the default UI and not promoting `v2` for full rollout. This experiment highlights the value of CE in preventing feature regressions that may seem visually appealing but harm actual usage. 
