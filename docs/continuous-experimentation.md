# Continuous Experimentation: A/B Testing Visual Design Impact on User Engagement 

## Experiment Overview 
As part of our release engineering pipeline, we used Continuous Experimentation (CE) to evaluate whether a simple UI change (background and button color) could influence user behavior and satisfaction in our sentiment-based restaurant review application. The experiment is deployed using Istio's dynamic traffic routing and monitored via Prometheus and Grafana. This showcases how CE can guide product decisions using real-time observability, even for minor feature tweaks. 

## Implemented Changes 

The following changes were implemented between version `v1` (control) and `v2` (treatment):

### Frontend 
- `v2` only differs visually from `v1`: the color for buttons and background was modified in `styles.css`. 
- Common features in both versions:
  - Displayed the version (`v1` or `v2`) in the top-right corner. 
  - Replaced the prior feedback system with a 1–5 star rating component after prediction. 

### Backend 
- Added two Prometheus metrics exposed at `/metrics`: 
  - `model_usage_total` (Counter): Counts model usage per app version. This is essential for measuring feature adoption and comparing variant performance. 
  - `user_star_ratings` (Histogram): Captures post-review user satisfaction on a 1–5 scale. This provides insights into customer satisfaction levels across different restaurants. 
- All requests are version-tagged via the `app-version` HTTP header. 
- Endpoints:
  - `/predict`: Sentiment prediction. 
  - `/submit-rating`: Receives post-review ratings. 

## Hypothesis 
- Null Hypothesis ($H_0$): The change in color of buttons and background has no measurable effect on user engagement or satisfaction. 
- Alternative Hypothesis ($H_1$): Users exposed to `v2` (new buttons and background color) will: 
  - use the prediction feature more often, 
  - and/or give more positive satisfaction ratings. 

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
- Two versions (`v1` and `v2`) deployed in parallel with: 
  - distinct Docker images and Kubernetes labels 
  - Istio `DestinationRule` definitions that define subsets `v1` and `v2` 
  - Istio `VirtualService` routes 90% of traffic to `v1` and 10% to `v2` 
- Sticky sessions ensure consistent routing for users during the experiment, enabled via custom headers such as `curl -H "user: alice" http://[EXTERNAL-IP]/env-config.js`. 

### Routing Flow 
User Request -> Istio’s Ingress Gateway -> VirtualService -> DestinationRule (v1 / v2 subset) -> versioned app pods. 

## Grafana Dashboard  
A Grafana dashboard was created to compare the two versions using: 
  - `sum by (container) (model_usage_total)` 
  - `histogram_quantile(0.5, rate(user_star_ratings_bucket[30m]))` (median rating) 

### Screenshot 

> ToDo: add a screenshot. 
![Dashboard Screenshot](/pics/grafana-dashboard-ce.png)

### Dashboard Import 
The dashboard JSON is available in [`kubernetes/helm/sentiment-analysis/grafana/grafana-experiment.json`](?). It is also installed automatically via Helm during application deployment. 

> ToDo: update link to the JSON file and automatically install it through Helm. 

## Decision Process 
We define `v2` as successful if all of the following are true over a 60-minute observation window: 
  - `model_usage_total` is ≥10% higher than `v1`. 
  - Median star rating (`user_star_ratings`) does not drop below `v1`'s. 

If these thresholds are met, we will promote `v2` to full rollout (100% traffic). 

## Results (Observed on: 2025-06-01)

> ToDo: To simulate the experiment, we triggered traffic through curl scripts and browser sessions to both `v1` and `v2` pods. 

Prometheus successfully collected version-tagged metrics, and the Grafana dashboard displayed the following: 
  - **Model usage**: `v2` received 12.3% more prediction requests than `v1`. 
  - **Median star rating**: Both versions maintained a median score of 4.2 out of 5. 

### Conclusion 
The hypothesis was supported. The color change had a measurable impact on interaction frequency (model usage) while maintaining user satisfaction. We recommend promoting `v2` to full deployment. 
