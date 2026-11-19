# personal-app

Eigene App fuer das iPhone, gebaut ohne Mac. Zwei Wege, gleicher Inhalt.

## Weg 1: PWA (dauerhaft, ohne Signatur)

`docs/` ist eine installierbare Web-App. Im Safari: Teilen, "Zum Homescreen". Kein Zertifikat, kein Ablauf, kein Refresh, kein Apple-Account.

Quelle fuer GitHub Pages: Branch `main`, Ordner `/docs`.
URL: https://marcelkwk.github.io/personal-app/

Daten liegen im localStorage des Geraets. "Sichern" legt eine JSON-Datei ab, langes Druecken auf "Sichern" liest sie wieder ein.

## Weg 2: Signierte Huelle (echtes App-Icon, Tetherless)

`ios/` ist eine SwiftUI-Huelle, die dieselbe Seite laedt. Aenderungen an der Web-App brauchen keinen neuen Build.

1. In Tetherless die neueste IPA aus den Releases laden.
2. Mit eigener Apple-ID signieren und installieren.

Der Workflow `.github/workflows/ios-ipa.yml` baut bei jedem Push auf `ios/**` eine unsignierte IPA und haengt sie an ein Release.

Haltedauer: Gratis-Apple-ID 7 Tage (Shortcut-Automatik mit "Refresh All Apps"), eigenes Jahreszertifikat 1 Jahr.

## Bauen

Die App selbst ist `docs/app.js` plus `docs/index.html`. Funktionen aendern heisst: diese beiden Dateien anfassen, `CACHE` in `docs/sw.js` hochzaehlen, pushen.
