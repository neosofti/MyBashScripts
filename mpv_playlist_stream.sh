#!/bin/bash
# Author: Milen Velikov <root@neosofti.org>
# Sicherstellen, dass Eingaben immer vom Terminal gelesen werden
exec </dev/tty

read -p "URL eingeben: " URL

if [ -z "$URL" ]; then
    echo "Fehler: Keine URL angegeben." >&2
    exit 1
fi

echo "Prüfe URL..."

# Metadaten mit yt-dlp abfragen
INFO_JSON=$(yt-dlp --dump-single-json --flat-playlist --no-warnings "$URL" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$INFO_JSON" ]; then
    echo "Fehler: URL konnte nicht verarbeitet werden oder yt-dlp ist nicht installiert." >&2
    exit 1
fi

# Abfragen, ob es sich um eine Playlist handelt
IS_PLAYLIST=$(echo "$INFO_JSON" | jq -r '._type // empty')

if [ "$IS_PLAYLIST" = "playlist" ]; then
    TITLE=$(echo "$INFO_JSON" | jq -r '.title // "Unbenannte Playlist"')
    COUNT=$(echo "$INFO_JSON" | jq -r '(.entries | length) // 0')

    echo ""
    echo "=========================================="
    echo "Playlist erkannt: $TITLE"
    echo "Anzahl der Einträge: $COUNT"
    echo "=========================================="
    echo "1) Gesamte Playlist abspielen"
    echo "2) Nur ein bestimmtes Video aus der Playlist abspielen"
    read -p "Auswahl (1 oder 2, Standard: 1): " PL_CHOICE

    if [ "$PL_CHOICE" = "2" ]; then
        read -p "Gebe die Nummer des Videos ein (1-$COUNT): " PLAYLIST_INDEX
        if [[ "$PLAYLIST_INDEX" =~ ^[0-9]+$ ]] && [ "$PLAYLIST_INDEX" -ge 1 ] && [ "$PLAYLIST_INDEX" -le "$COUNT" ]; then
            echo "Hole URL für Eintrag $PLAYLIST_INDEX..."
            # Extrahiere die direkte Video-URL für den gewählten Index
            URL=$(yt-dlp --flat-playlist --print url --playlist-items "$PLAYLIST_INDEX" "$URL" 2>/dev/null)
            if [ -z "$URL" ]; then
                echo "Fehler: Konnte die Video-URL nicht extrahieren." >&2
                exit 1
            fi
        else
            echo "Ungültige Eingabe. Spiele gesamte Playlist ab."
        fi
    fi
fi

echo ""
echo "Wähle den Wiedergabemodus:"
echo "1) Nur Audio (kein Video)"
echo "2) Video + Audio"
read -p "Auswahl (1 oder 2, Standard: 1): " MODE

case "$MODE" in
    2)
        echo "Starte Video-Wiedergabe..."
        mpv --ytdl-format="bestvideo+bestaudio/best" "$URL"
        ;;
    *)
        echo "Starte reinen Audio-Stream..."
        mpv --no-video --ytdl-format="bestaudio/best" "$URL"
        ;;
esac
