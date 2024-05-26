{{/*
Expand the name of the chart.
*/}}
{{- define "node-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "node-service.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create config secret name.
*/}}
{{- define "node-service.configSecretName" -}}
{{- printf "%s-config" (include "node-service.fullname" .) }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "node-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "node-service.labels" -}}
helm.sh/chart: {{ include "node-service.chart" . }}
{{ include "node-service.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "node-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "node-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "node-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "node-service.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Merge environment variables from values.yaml and secrets.
If an environment variable is defined in values.yaml, it takes precedence.
*/}}
{{- define "node-service.envVars" -}}
{{- $envVars := dict -}}
{{- range $env := .Values.env }}
{{- $envVars.Set $env.name $env.value }}
{{- end }}
{{- range $key, $value := .Values.envFrom.secret }}
{{- if not ($envVars.Has $key) }}
{{- $envVars.Set $key (dict "secretKeyRef" (dict "name" (include "node-service.configSecretName" $) "key" $key)) }}
{{- end }}
{{- end }}
{{- range $key, $value := $envVars }}
- name: {{ $key }}
{{- if typeIs "string" $value }}
  value: {{ $value | quote }}
{{- else }}
  valueFrom:
    secretKeyRef:
      name: {{ $value.secretKeyRef.name }}
      key: {{ $value.secretKeyRef.key }}
{{- end }}
{{- end }}
{{- end -}}
