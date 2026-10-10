FROM nginxinc/nginx-unprivileged:1.27-alpine
COPY index.html /usr/share/nginx/html/index.html
COPY nginx-k8s.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
