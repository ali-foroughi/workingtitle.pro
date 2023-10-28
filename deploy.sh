#!/bin/sh
USER=root
HOST=141.11.182.13
DIR=/var/www/workingtitle.pro/   # the directory where your web site files should go

hugo && rsync -avz -e "ssh -p 9011" --delete public/ ${USER}@${HOST}:${DIR}

exit 0
