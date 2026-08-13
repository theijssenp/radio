# Hodc FM

Statische radiopagina: 32 live streams, sleepbare volgorde, één bestand.
Doel: `https://radio.hodc.nl`

## Bestanden

| Bestand | Wat |
|---|---|
| `index.html` | De hele app — HTML, CSS, JS en de zenderlijst. Geen build, geen dependencies. |
| `deploy/radio.hodc.nl.conf` | Apache vhost (alleen poort 80 — zie Uitrollen). |
| `deploy/uitrollen.sh` | Rsync van de pagina naar de server. |

## Zender toevoegen of wijzigen

De lijst staat bovenaan het `<script>`-blok in `index.html` als `ZENDERS`:

```js
{ band: "Nederland", naam: "NPO 3FM", plaats: "Hilversum", kbps: 192, url: "https://icecast.omroep.nl/3fm-bb-mp3" },
```

Eisen aan een stream-URL:

- **https**, anders blokkeert de browser hem op een https-pagina.
- **mp3 of aac**. Een `.m3u8` werkt alleen in Safari; een `.pls`/`.m3u` is een playlist — open die en pak de URL eruit.
- Nieuwe URLs zoeken: <https://www.radio-browser.info/>

De `band`-waarde bepaalt onder welke kop een zender valt; een nieuwe bandnaam
maakt automatisch een nieuwe sectie aan, in de volgorde van eerste voorkomen.

## Favorieten

Bovenaan staat een band **Favorieten** die niet uit `ZENDERS` komt. Hij is bij
een verse start leeg en blijft dan als dropzone staan; sleep er zenders in die
je vaak gebruikt.

Een zender *verhuist* ernaartoe — hij verdwijnt dus uit Nederland, Wereld of
waar hij vandaan kwam, precies zoals slepen tussen twee gewone banden werkt.
Sleep hem terug om dat ongedaan te maken. Wil je dat een favoriet óók op zijn
oude plek blijft staan, dan is dat een andere functie: dan moet een zender op
twee plaatsen tegelijk kunnen staan, en dat kan de huidige opzet niet.

De inhoud gaat mee in dezelfde `localStorage`-sleutel als de rest van de
volgorde, dus "Herstel volgorde" leegt ook je favorieten.

## Volgorde slepen

Elke kaart heeft rechts een greep. Slepen werkt met muis, trackpad en touch
(pointer events — de HTML5 drag-and-drop API doet het niet op iOS Safari).
Slepen tussen banden mag; de zender neemt de band van zijn nieuwe sectie over.
Met de greep gefocust verplaatsen de pijltjestoetsen de kaart — ook een lege
band in, zodat je met het toetsenbord bij Favorieten kunt komen.

De luisteraars voor het slepen hangen aan `document`, niet aan de greep. Dat
moet zo blijven: bij de eerste herordening verhuist de kaart mét de greep in de
DOM, en dan laat de browser de pointer capture los. Luisteraars op de greep
kregen daarna niets meer binnen — ook de `pointerup` niet — waardoor het slepen
na één stap vastliep.

De volgorde gaat naar `localStorage` onder `hodcfm.volgorde.v1` en staat dus
per apparaat. "Herstel volgorde" rechtsboven zet alles terug naar de volgorde
zoals die in `ZENDERS` staat; die knop verschijnt pas zodra je iets versleept
hebt.

Een leeggesleepte band blijft als dropzone staan, zodat je er zenders in kunt
terugleggen.

## Lokaal bekijken

```bash
python3 -m http.server 8899 --bind 127.0.0.1
```

Dan <http://127.0.0.1:8899/>. Openen via `file://` kan ook, maar dan is de
charset-detectie van de browser wisselvalliger.

## Uitrollen

De site staat live sinds 13 augustus 2026. Een update is één commando:

```bash
./deploy/uitrollen.sh
```

Dat rsynct alleen `index.html` naar `/var/www/radio.hodc.nl/` en heeft geen
sudo nodig — de docroot is van `pieter`. Het script controleert vooraf of
docroot en vhost bestaan en zegt wat er moet gebeuren als dat niet zo is.

De server is `pieter@192.168.1.109` (herm, binnendoor over het LAN). Geef een
andere host mee als eerste argument.

### Hoe het draait

Herm serveert de hele hodc.nl-familie via een **Cloudflare-tunnel**. In
`~/.cloudflared/config.yml` staat een ingress-regel voor `*.hodc.nl` die naar
`http://localhost:80` wijst, dus radio.hodc.nl viel daar automatisch onder.

Gevolg: **Cloudflare termineert TLS en de tunnel praat plain http met Apache.**
Daarom heeft de vhost alleen een `:80`-blok en is er geen certbot en geen
Let's Encrypt-certificaat in het spel. Een `:443`-blok op de origin zou hier
niets doen behalve de configtest laten falen.

### Eerste installatie op een nieuwe server

`sudo` op herm vraagt een wachtwoord, dus de root-stappen gaan handmatig.
Kopieer `index.html`, `radio.hodc.nl.conf` en een installatiescript naar
`~/radio-hodc/` op de server en draai daar eenmalig:

```bash
sudo mkdir -p /var/www/radio.hodc.nl
sudo chown $USER:$USER /var/www/radio.hodc.nl
sudo cp radio.hodc.nl.conf /etc/apache2/sites-available/
sudo a2enmod headers
sudo a2ensite radio.hodc.nl
sudo apache2ctl configtest && sudo systemctl reload apache2
```

En het DNS-record — dit hoeft niet als root, want `~/.cloudflared/cert.pem`
staat al op de server:

```bash
cloudflared tunnel route dns a4e5e0a8-718d-471e-aa46-321d34b3f5e7 radio.hodc.nl
```

Origin testen buiten Cloudflare om:

```bash
curl -I -H 'Host: radio.hodc.nl' http://localhost/
```
