#!/usr/bin/env bash
# Rolt Hodc FM uit naar radio.hodc.nl op de server 'herm'.
# Draaien vanuit de projectmap of via ./deploy/uitrollen.sh — het script
# bepaalt zijn eigen paden.
set -euo pipefail

HOST="${1:-pieter@192.168.1.109}"
ROOT="/var/www/radio.hodc.nl"
HIER="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$(cd "$HIER/.." && pwd)"

echo "==> Verbinding testen met ${HOST}"
ssh -o ConnectTimeout=10 "$HOST" 'echo "  verbonden met $(hostname)"'

echo "==> Controleren of de docroot bestaat"
if ! ssh "$HOST" "test -w '$ROOT'"; then
  cat <<EOF

  ${ROOT} bestaat niet of is niet schrijfbaar.
  /var/www is root:root en sudo op deze server vraagt een wachtwoord, dus
  dit stukje gaat handmatig. Draai eenmalig:

    ssh ${HOST}
    sudo mkdir -p ${ROOT} && sudo chown \$USER:\$USER ${ROOT}

  Daarna werkt dit script verder zonder sudo.
EOF
  exit 1
fi

echo "==> Pagina kopiëren"
rsync -avz --checksum "$PROJECT/index.html" "$HOST:$ROOT/index.html"

echo "==> Controleren of de vhost actief is"
if ssh "$HOST" 'test -e /etc/apache2/sites-enabled/radio.hodc.nl.conf'; then
  echo "  vhost staat aan"
else
  scp "$HIER/radio.hodc.nl.conf" "$HOST:/tmp/radio.hodc.nl.conf"
  cat <<EOF

  De vhost staat nog niet aan. Hij is naar /tmp gekopieerd; activeer hem
  eenmalig met:

    ssh ${HOST}
    sudo mv /tmp/radio.hodc.nl.conf /etc/apache2/sites-available/
    sudo a2enmod headers
    sudo a2ensite radio.hodc.nl
    sudo apache2ctl configtest && sudo systemctl reload apache2
EOF
  exit 1
fi

echo "==> Klaar. Controleer met:"
echo "    curl -I https://radio.hodc.nl"
