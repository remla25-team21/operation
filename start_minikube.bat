:: filepath: /home/bowen/files/remla25-team21/operation/start_minikube.bat
@echo off
setlocal enabledelayedexpansion

:: Set colors for Windows console
set "GREEN=[92m"
set "BLUE=[94m"
set "YELLOW=[93m"
set "RED=[91m"
set "NC=[0m"

:: Parse command line arguments
set "STEP="

:parse_args
if "%~1"=="" goto check_args
if /i "%~1"=="--step" (
    set "STEP=%~2"
    shift /1
    shift /1
    goto parse_args
) else (
    echo %RED%Error: Unknown parameter: %~1%NC%
    echo %YELLOW%Usage: %~0 --step 1^|2%NC%
    exit /b 1
)

:check_args
:: Check if step is provided and valid
if not "%STEP%"=="1" if not "%STEP%"=="2" (
    echo %RED%Error: You must specify which step to run%NC%
    echo %YELLOW%Usage: %~0 --step 1^|2%NC%
    echo %YELLOW%  --step 1: Setup infrastructure (Minikube, Prometheus, Istio)%NC%
    echo %YELLOW%  --step 2: Deploy application%NC%
    exit /b 1
)

echo %BLUE%===== Minikube Setup Script for Sentiment Analysis App =====%NC%

:: Check if necessary tools are installed
for %%t in (minikube.exe kubectl.exe helm.exe istioctl.exe) do (
    where %%t >nul 2>nul || (
        echo %RED%Error: %%t is not installed. Please install it first.%NC%
        exit /b 1
    )
)
echo %GREEN%All necessary tools are installed.%NC%

:: Step 1: Infrastructure setup
if "%STEP%"=="1" (
    echo %BLUE%[STEP 1] Setting up infrastructure...%NC%

    echo %BLUE%[1/4]%NC% Cleaning up any existing Minikube clusters...
    minikube delete --all >nul 2>nul || ver >nul

    echo %BLUE%[2/4]%NC% Starting Minikube...
    minikube start --memory=4096 --cpus=4 --driver=docker
    minikube addons enable ingress
    echo %GREEN%Minikube started successfully!%NC%

    echo %BLUE%[3/4]%NC% Installing Prometheus stack...
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >nul 2>nul
    helm repo update >nul 2>nul
    helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
    echo %GREEN%Prometheus stack installed!%NC%

    echo %BLUE%[4/4]%NC% Installing Istio and its add-ons...
    istioctl install -y
    kubectl apply -f kubernetes\istio-addons\prometheus.yaml
    kubectl apply -f kubernetes\istio-addons\jaeger.yaml
    kubectl apply -f kubernetes\istio-addons\kiali.yaml
    kubectl label ns default istio-injection=enabled --overwrite
    echo %GREEN%Istio installed!%NC%
  
    echo %GREEN%Infrastructure setup complete! (Step 1)%NC%
    echo %YELLOW%To deploy the application, run: %~0 --step 2%NC%
)

:: Step 2: Application deployment
if "%STEP%"=="2" (
    echo %BLUE%[STEP 2] Deploying application...%NC%

    echo %BLUE%[1/2]%NC% Deploying the application...
    
    :: Get external IP for istio-ingressgateway
    for /f "tokens=*" %%i in ('kubectl get svc istio-ingressgateway -n istio-system -o jsonpath^="{.status.loadBalancer.ingress[0].ip}"') do (
        set "EXTERNAL_IP_RAW=%%i"
    )

    if "!EXTERNAL_IP_RAW!"=="" (
        echo %RED%No external IP found for istio-ingressgateway. Run 'minikube tunnel' in a separate terminal first.%NC%
        exit /b 1
    )

    set "EXTERNAL_IP=!EXTERNAL_IP_RAW!"

    echo %YELLOW%Using '!EXTERNAL_IP!' for istio.ingressGateway.host in Helm chart.%NC%
    helm install my-sentiment-analysis .\kubernetes\helm\sentiment-analysis --set istio.ingressGateway.host=!EXTERNAL_IP!
    echo %GREEN%Application deployed!%NC%

    echo %BLUE%[2/2]%NC% Waiting for pods to be ready...
    kubectl wait --for=condition=ready pod --all --timeout=300s || ver >nul
    echo %GREEN%Pod readiness check complete.%NC%

    echo %BLUE%Waiting a few seconds for network routes to establish...%NC%
    timeout /t 5 >nul

    if "!EXTERNAL_IP!"=="" if "!EXTERNAL_IP!"=="<pending>" if "!EXTERNAL_IP!"=="pending" (
        echo %RED%Could not determine external IP for istio-ingressgateway.%NC%
        echo %YELLOW%This usually means 'minikube tunnel' is not running or not working correctly.%NC%
        echo %YELLOW%Please run minikube tunnel and try again.%NC%
        exit /b 1
    ) else (
        echo %GREEN%Successfully retrieved External IP: !EXTERNAL_IP!%NC%
    )

    echo.
    echo %GREEN%===========================%NC%
    echo %GREEN%Access Your Services:%NC%
    echo %YELLOW%1. Run %NC%minikube tunnel%YELLOW% in a separate terminal%NC%
    echo %YELLOW%2. Application URL:%NC% http://!EXTERNAL_IP!
    echo.
    echo %YELLOW%To access dashboards, run these commands in separate terminals:%NC%
    echo %YELLOW%1. Prometheus Dashboard:%NC% kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090
    echo %YELLOW%2. Grafana Dashboard:%NC% kubectl -n monitoring port-forward service/prometheus-grafana 3300:80
    echo %YELLOW%3. Kiali Dashboard:%NC% kubectl -n istio-system port-forward svc/kiali 20001:20001
    echo.
    echo %GREEN%===========================%NC%
)

echo %GREEN%Script finished.%NC%
endlocal