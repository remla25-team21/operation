# Sentiment Analysis Helm Chart

This Helm chart deploys the Restaurant Review Sentiment Analysis application, which includes a model service for sentiment analysis and a web application frontend/backend.

## Installation

1. First, ensure you have your Kubernetes cluster running (e.g., with `minikube start`)

2. Install the chart:

   ```bash
   helm install my-sentiment-analysis ./sentiment-analysis
   ```
