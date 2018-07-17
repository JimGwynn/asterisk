import sys
import os
import subprocess

filepath = sys.argv[1]
if not os.path.isfile(filepath):
  print("File path {} does not exist. Exiting..".format(filepath))
  sys.exit()
with open(filepath) as fp:
  cnt = 0
  for line in fp:
    line = line.rstrip()
    keys = line.split(":")
    print("file:{} text:{}".format(keys[0],keys[1]))
    polly = "/usr/bin/aws polly synthesize-speech --output-format mp3 --voice-id Salli --text '{}'  t.mp3".format(keys[1])
    sox = "/usr/bin/sox t.mp3 -r 8000 -c 1 -t gsm {}.gsm".format(keys[0])
    subprocess.call(polly,shell=True)
    subprocess.call(sox,shell=True)


