#!/bin/bash
/usr/bin/aws polly synthesize-speech --output-format mp3 --voice-id Salli --text "$1" /tmp/$2.mp3
#/usr/bin/mpg123 -q --wav /tmp/t.wav  --rate 8000 --mono /tmp/t.mp3
/usr/bin/sox /tmp/$2.mp3 -r 8000 -c 1 -t gsm /tmp/$2.gsm
rm /tmp/$2.mp3
#rm /tmp/t.wav
