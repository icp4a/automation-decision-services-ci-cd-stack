{{/*
Create helm partial for gitea server
*/}}
{{- define "gitea" }}
- name: gitea
  image: {{ .Values.images.gitea.name }}:{{ .Values.images.gitea.tag }}
  imagePullPolicy: {{ .Values.images.pullPolicy }}
  env:
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "db.fullname" . }}
        key: dbPassword
  - name: GITEA_INIT_CONFIG_DIR
    value: /etc/gitea-init-config
  - name: GITEA_INIT_TOUCHPOINT
    value: /data/gitea-init-touchpoint
  ports:
  - name: ssh
    containerPort: {{ .Values.service.ssh.port  }}
  - name: http
    containerPort: {{ .Values.service.http.port  }}
  livenessProbe:
    tcpSocket:
      port: http
    initialDelaySeconds: 200
    timeoutSeconds: 1
    periodSeconds: 10
    successThreshold: 1
    failureThreshold: 10
  readinessProbe:
    exec:
      command:
      - ls
      - /data/gitea-init-touchpoint
    initialDelaySeconds: 5
    periodSeconds: 10
    successThreshold: 1
    failureThreshold: 3
  resources:
{{ toYaml .Values.resources.gitea | indent 10 }}
  volumeMounts:
  - name: gitea-data
    mountPath: /data
  - name: gitea-config
    mountPath: /etc/gitea
  - name: gitea-init-config
    mountPath: /etc/gitea-init-config
{{- end }}
