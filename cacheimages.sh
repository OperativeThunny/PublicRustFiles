#!/usr/bin/env bash
#
# This script will generate a list of urls to cache for a local nginx web server
# with traefik in front with the /etc/hosts file updated to send trafic destined
# to imgur to it, so it needs to extract all URLs to get from imgur by
# extrafcting all urls from the game directory specifically tnhe config files
# for the rust plugins.
# ==============================================================================
# Scripts by OperativeThunny - Contact me for different licensing if you want something other than AGPL licensing. 
# Copyright (C) 2023 @OperativeThunny

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ==============================================================================


set -Eeou pipefail
# Function to handle errors
error_handler() {
    echo "$0: Error occurred on line $1"
    echo "Exiting with status $2"
    exit $2
}
# Trap errors and call the error handler function
trap 'error_handler $LINENO $? $0' ERR

# wow this is cool, it sends stdout and stderr to syslog and I can see it with
# journalctl -f -t generateUrlsToCache.sh and I had no idea this was possible
# until I saw it in suggested code from copilot
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Yes, this could be one continuous pipeline but what if in the future I want to do something with the intermediate step data?? HMM?!??! WHAT THEN!?!?!?!
# also, yes, it needs powershell to be installed on linux because powershell is awesome!
directory_to_search=/opt/rustserver/live/
allurls_file=/opt/www/webimgur/0001allurls.txt
sorted_unique_file=/opt/www/webimgur/0002uniqurls.txt
likely_image_urls_file=/opt/www/webimgur/0003imgurls.txt
likely_imgur_urls_file=/opt/www/webimgur/0004imgururls.txt
imgurl_urls_to_download_file=/opt/www/webimgur/0005imgururls_to_download.txt
grep -I -R -o -i -E "(http|https)://[a-zA-Z0-9./?=_%:-]*" $directory_to_search > $allurls_file
cut -d ":" -f 2- $allurls_file | grep -v -i -E "_0\$" | sort -u > $sorted_unique_file
grep -i -E "(png|jpg|jpeg|gif|bmp|tif|tiff|eps|webp|psd|raw|heif|indd|svg|jpe|jif|jfif|jfi|arw|cr2|nrw|k25|dib|heic|ind|indt|jp2|j2k|jpf|jpx|jpm|mj2|svgz|ai).*$" $sorted_unique_file > $likely_image_urls_file
grep -i -E "imgur" $likely_image_urls_file | sort -u > $likely_imgur_urls_file

ls -hl $allurls_file $sorted_unique_file $likely_image_urls_file $likely_imgur_urls_file
pwsh -Command '$files = gci /opt/www/webimgur/; (get-content ' $likely_imgur_urls_file ' | %{ $urlFile = ($_ | split-path -Leaf); if ( !(gci -erroraction silentlycontinue $urlFile) ) { $_ } })' > $imgurl_urls_to_download_file

#to do the thing with the thing do it like this to turn this into this
# server/hillside_exiles_identity/cfg/serverauto.cfg:https://icecast.thisisdax.com/CapitalGlasgowMP3
# server/hillside_exiles_identity/cfg/serverauto.cfg:https://443-1.autopo.st/130/
# server/hillside_exiles_identity/cfg/serverauto.cfg:https://stream.zeno.fm/jwyvpjgu5e7uv
# turns into this ->
# https://icecast.thisisdax.com/CapitalGlasgowMP3
# https://443-1.autopo.st/130/
# https://stream.zeno.fm/jwyvpjgu5e7uv
# cut delimiter colon grab fields 2 and onward
#cut -d ":" -f 2-
#grep -Ri 'https://i.img'  2>/dev/null | grep -v 'oxide/logs' | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | sort -u > /opt/www/webimgur/urls.txt
#grep -Ri imgur | grep -v 'oxide/logs' | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | sort -u > /opt/www/webimgur/urls2.txt

