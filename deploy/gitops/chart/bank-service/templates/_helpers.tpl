{{- define "bank.labels" -}}
app.kubernetes.io/name: {{ .Values.name }}
app.kubernetes.io/part-of: digital-banking
tier: {{ .Values.tier }}
{{- end -}}
{{- define "bank.selector" -}}
app.kubernetes.io/name: {{ .Values.name }}
{{- end -}}
