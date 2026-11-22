# The lighthouse module's test image (ci-lighthouse.yml): one static page,
# served by BusyBox's httpd. BusyBox carries no package database, so Trivy has
# nothing to match against, and the test doesn't fail on someone else's CVE.
FROM busybox:1.38.0-musl@sha256:80e38f9a1b39188b8bdb28879178edb322a4402b081a9aedda1924609decd6f6
COPY index.html /www/
USER 65534
EXPOSE 8080
CMD ["httpd", "-f", "-p", "8080", "-h", "/www"]
