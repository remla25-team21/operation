{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "sentiment-analysis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sentiment-analysis.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Get the Istio Gateway host address.
This function is used as a fallback when .Values.istio.ingressGateway.host is not set.
*/}}
{{- define "getIstioGatewayHost" -}}
{{- /* In a real deployment, you would dynamically get this value */ -}}
{{- /* Since we can't run kubectl commands from Helm templates directly, */ -}}
{{- /* we'll use a DNS name that resolves to the istio-ingressgateway service */ -}}
{{- "istio-ingressgateway.istio-system.svc" -}}
{{- end -}}