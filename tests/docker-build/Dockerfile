# The docker-build module's test image (ci-docker-build.yml). Empty, so Trivy
# finds nothing to flag and the test never fails on someone else's CVE. The
# label proves a build argument reached the build.
FROM scratch
ARG MESSAGE=unset
LABEL test.message=$MESSAGE
COPY hello.txt /
