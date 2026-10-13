FROM quay.io/keycloak/keycloak:26.6.4

# Band Manager login theme (hardened templates, brand)
COPY bandmanager-keycloak-theme.jar /opt/keycloak/providers/bandmanager-keycloak-theme.jar

# Canonical windband realm: users + clients incl. windband-inventory (ops admin mbz-admin)
COPY windband-realm.json /opt/keycloak/data/import/windband-realm.json

# Import on every startup: keycloak 26 exposes --import-realm ONLY as a CLI flag
# (conf-file keys and KC_IMPORT_REALM env are both ignored — verified empirically).
# Wrap kc.sh so `start` always gets the flag, regardless of the start command used.
RUN mv /opt/keycloak/bin/kc.sh /opt/keycloak/bin/kc.sh.orig && \
    printf '%s\n' \
      '#!/bin/sh' \
      'if [ "$1" = "start" ] || [ "$1" = "start-dev" ]; then' \
      '  exec /opt/keycloak/bin/kc.sh.orig "$@" --import-realm' \
      'else' \
      '  exec /opt/keycloak/bin/kc.sh.orig "$@"' \
      'fi' > /opt/keycloak/bin/kc.sh && \
    chmod 755 /opt/keycloak/bin/kc.sh

EXPOSE 8080
