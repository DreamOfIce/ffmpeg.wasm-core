const base = require('./transcode-base');
base('mt','core-mt');
base('mt','core-mt.mp4-scale',(name) => name == 'mp4 scale');
base('mt','core-mt.png-to-mp4',(name) => name == 'png to mp4');
