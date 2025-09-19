{{/*
Expand the name of the chart.
*/}}
{{- define "github-provider-kog.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "github-provider-kog.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "github-provider-kog.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "github-provider-kog.labels" -}}
helm.sh/chart: {{ include "github-provider-kog.chart" . }}
{{ include "github-provider-kog.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "github-provider-kog.selectorLabels" -}}
app.kubernetes.io/name: {{ include "github-provider-kog.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "github-provider-kog.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "github-provider-kog.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "webServiceUrl" -}}
http://{{ include "github-provider-kog.fullname" . }}-{{ .Values.plugin.suffix | default "plugin" }}.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.service.port }}
{{- end -}}

{{/*
Check if the plugin deployment is enabled.
Logic:
- Define a static list of resource definitions that require the plugin.
- Loop through all the enabled restdefinitions from values.yaml.
- If an enabled definition's name is in the static list, print "true".
*/}}
{{- define "github-provider-kog.plugin.enabled" -}}
{{- $requiresPluginList := list "collaborator" "teamrepo" -}}
{{- $enabled := false -}}
{{- range $key, $value := .Values.restdefinitions -}}
{{- if and $value.enabled (has $key $requiresPluginList) -}}
{{- $enabled = true -}}
{{- end -}}
{{- end -}}
{{- printf "%t" $enabled -}}
{{- end -}}
