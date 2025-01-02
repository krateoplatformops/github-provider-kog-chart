{{/*
Helper template to define server URLs from the OpenAPI Specification files.
*/}}

{{- define "webServiceUrl" -}}
http://{{ .Release.Name }}-plugin-krateo.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.webservice.service.port }}
{{- end -}}

{{- define "my-helm-chart.serverUrl" -}}
{{- $url := .Values.openapi.serverUrl -}}
{{- if $url -}}
{{ $url | quote }}
{{- else -}}
""
{{- end -}}
{{- end -}}

{{/*
Helper template to define web service URLs from the OpenAPI Specification files.
*/}}

{{- define "my-helm-chart.webServiceUrl" -}}
{{- $url := .Values.openapi.webServiceUrl -}}
{{- if $url -}}
{{ $url | quote }}
{{- else -}}
""
{{- end -}}
{{- end -}}

{{/*
Helper template to generate labels for resources.
*/}}

{{- define "my-helm-chart.labels" -}}
app: {{ .Chart.Name }}
release: {{ .Release.Name }}
{{- end -}}