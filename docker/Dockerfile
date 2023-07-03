FROM scalingo/${SCALINGO_STACK:-scalingo-22} as build

# Buildpacks `compile` script expects 3 parameters:
# - build dir
# - cache dir
# - environment dir
# These 3 directories are especially used by Scalingo php-buildpack
RUN mkdir -p /buildpack /build /cache /env ; chown appsdeck. /buildpack /build /cache /env

# use git files from archives
COPY buildpack.tar.gz /buildpack/
COPY scalingo-build.sh /buildpack/
# mimic scalingo build
RUN chmod +x /buildpack/scalingo-build.sh && \
    /buildpack/scalingo-build.sh && \
    rm -rf /app /buildpack /cache && \
    mv /build /app && \
    > /start && chmod +x /start && \
    cat <<'EOF' >> /start
#!/bin/bash
# mimic Procfile start script
shift
[ -d ".profile.d" ] && for f in .profile.d/*; do . $f; done || true
[ -f "${HOME}/.profile" ] && source "${HOME}/.profile" || true
eval "umask 0077; $@ </dev/null"
EOF

FROM scalingo/${SCALINGO_STACK:-scalingo-22}
COPY --from=build /app /app
COPY --from=build /start /start

# All Scalingo apps define a listening port
ENV PORT=80

# The default Scalingo app Docker image directory is /app
WORKDIR /app

# Scalingo Docker image defines a user `appsdeck` that is used during execution
RUN chown -R appsdeck: /app
USER appsdeck

# Reproduce Scalingo execution of Procfile
CMD ["/bin/bash", "-c", "sleep 30 ; source .profile.d/php.sh && /start web /app/bin/nextcloud.sh"]
