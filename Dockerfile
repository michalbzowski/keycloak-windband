FROM quay.io/keycloak/keycloak:26.6.4

# Band Manager login theme (hardened templates)
COPY bandmanager-keycloak-theme.jar /opt/keycloak/providers/bandmanager-keycloak-theme.jar

# windband realm import file with __PLACEHOLDERS__ for secrets --
# injected at container start from Keycloak service env vars
# (KC_WBM_CLIENT_SECRET, KC_MBZ_ADMIN_PASSWORD) by the kc.sh wrapper below.
RUN mkdir -p /opt/keycloak/data/import && chown keycloak:keycloak /opt/keycloak/data/import
COPY --chown=keycloak:keycloak windband-realm.json /opt/keycloak/data/import/windband-realm.json
RUN chmod 664 /opt/keycloak/data/import/windband-realm.json

# Keycloak 26: --import-realm exists ONLY as a CLI flag (conf-file and
# KC_IMPORT_REALM env are both ignored). The wrapper also patches the
# secret placeholders in before starting, so no secret ever ships in the image.
RUN mv /opt/keycloak/bin/kc.sh /opt/keycloak/bin/kc.sh.orig && \
    printf '%s\n' \
      '#!/bin/sh' \
      'F=/opt/keycloak/data/import/windband-realm.json' \
      'if [ -f "$F" ]; then' \
      '  if [ -n "$KC_WBM_CLIENT_SECRET" ] && grep -q "__WM_CLIENT_SECRET__" "$F"; then' \
      '    sed -i "s|__WM_CLIENT_SECRET__|$KC_WBM_CLIENT_SECRET|" "$F"' \
      '  fi' \
      '  if [ -n "$KC_MBZ_ADMIN_PASSWORD" ] && grep -q "__MBZ_ADMIN_PASSWORD__" "$F"; then' \
      '    sed -i "s|__MBZ_ADMIN_PASSWORD__|$KC_MBZ_ADMIN_PASSWORD|" "$F"' \
      '  fi' \
      'fi' \
      'if [ "$1" = "start" ] || [ "$1" = "start-dev" ]; then' \
      '  exec /opt/keycloak/bin/kc.sh.orig "$@" --import-realm' \
      'else' \
      '  exec /opt/keycloak/bin/kc.sh.orig "$@"' \
      'fi' > /opt/keycloak/bin/kc.sh && \
    chmod 755 /opt/keycloak/bin/kc.sh

EXPOSE 8080
