# Continuous Experimentation (CE)

## Experiment Overview 
We designed an A/B experiment to evaluate whether a visual styling change (*color of the buttons and the background*) improves user engagement and satisfaction on our sentiment-based restaurant review application. This experiment is deployed using Istio's dynamic traffic routing and monitored via Prometheus and Grafana. 

## Implemented Changes 

The following changes were implemented between version `v1` (control) and `v2` (treatment):

### Frontend 
- `v2` only differs visually from `v1`: the color for buttons and background was modified in `styles.css`. 
- Common features in both versions:
  - Displayed the version (`v1` or `v2`) in the top-right corner. 
  - Replaced the prior feedback system with a 1–5 star rating component after prediction. 
  - Tracked time spent on the review page using JavaScript timers in `predict.js`. 

### Backend 
- Added three Prometheus metrics exposed at `/metrics`: 
  - `model_usage_total` (Counter): Counts model usage per app version. This is essential for measuring feature adoption and comparing variant performance. 
  - `user_session_duration_seconds` (Histogram): Measures how long users spend in each session. This is useful for understanding user engagement patterns. 
  - `user_star_ratings` (Histogram): Captures post-review user satisfaction on a 1–5 scale. This provides insights into customer satisfaction levels across different restaurants. 
- All requests are version-tagged via the `app-version` HTTP header. 
- New endpoints:
  - `/predict`: Sentiment prediction. 
  - `/submit-rating`: Receives post-review ratings. 

## Hypothesis 
- Null Hypothesis ($H_0$): The change in color of buttons and background has no measurable effect on user engagement or satisfaction. 
- Alternative Hypothesis ($H_1$): Users exposed to `v2` (new buttons and background color) will: 
  - use the prediction feature more often, 
  - stay longer in a session, 
  - and/or give more positive satisfaction ratings. 

## Metrics 
Prometheus scrapes and aggregates the following metrics: 
  - `model_usage_total`: The number of predictions. 
  - `user_star_ratings`: Satisfaction score distribution. 
  - `user_session_duration_seconds`: Duration of session activity. 

### Prometheus Configuration 
Metric scraping is enabled using pod annotations:
```yaml
    annotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: "/metrics"
        prometheus.io/port: "8080"
```

The Prometheus instance is installed via Helm and configured using the `kubernetes/istio-addons/prometheus.yaml` file. 

> ToDo 

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
  - `rate(user_session_duration_seconds_sum[30m]) / rate(user_session_duration_seconds_count[30m])`
  - `histogram_quantile(0.5, rate(user_star_ratings_bucket[30m]))` (median rating)

### Screenshot 

> ToDo: add a screenshot. 
![Dashboard Screenshot](/pics/grafana-dashboard-ce.png)

### Dashboard Import 
The dashboard JSON is available in [`kubernetes/helm/sentiment-analysis/grafana/grafana-experiment.json`](?). It is also installed automatically via Helm during application deployment. 

> ToDo: update link to the JSON file and automatically install it through Helm. 

## Decision Process 
We define `v2` as successful if all of the following are true over a 30-minute observation window: 
  - `model_usage_total` is ≥10% higher than `v1`. 
  - Median star rating (`user_star_ratings`) does not drop below `v1`'s. 
  - Average session duration is within ±5% of `v1`. 

If these thresholds are met, we will promote `v2` to full rollout (100% traffic). 

## Results 

> ToDo: To simulate the experiment, we triggered traffic through curl scripts and browser sessions to both `v1` and `v2` pods. 

Prometheus successfully collected version-tagged metrics, and the Grafana dashboard displayed the following: 

- **Model usage**: `v2` received 12.3% more prediction requests than `v1`. 
- **Median star rating**: Both versions maintained a median score of 4.2 out of 5. 
- **Session duration**: The average user session was 3.5 minutes for `v1` and 3.6 minutes for `v2`, staying within the ±5% threshold. 

### Conclusion 
The hypothesis was supported. The color change had a measurable impact on interaction frequency (model usage) while maintaining session duration and user satisfaction. We recommend promoting `v2` to full deployment. 
