# Sentiment Analysis Helm Chart

This Helm chart deploys the Restaurant Review Sentiment Analysis application, which includes a model service for sentiment analysis and a web application frontend/backend.

## Installation

1. First, ensure you have your Kubernetes cluster running (e.g., with `minikube start`)
2. Make sure that you are inside of the sentiment-analysis folder.
3. Install the chart:
   ```bash
   helm install my-sentiment-analysis ./sentiment-analysis
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
6. Access the application from `http://localhost:3000`.
