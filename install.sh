#!/bin/sh
# Copyright (c) 2016 Andrejs Mivreņiks
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
if [[ -z "$HOME" ]]; then
    echo 'Environment variable HOME is not set.'
    exit
fi
mpv_scripts_dir="${HOME}/.config/mpv/scripts"; mkdir -p "$mpv_scripts_dir"
mpv_lua_settings_dir="${HOME}/.config/mpv/lua-settings"; mkdir -p "$mpv_lua_settings_dir"
mpv_myshows_conf="$mpv_lua_settings_dir/myshows.conf"

wget -O "$mpv_scripts_dir/myshows.lua" 'https://raw.githubusercontent.com/gim-/mpv-plugin-myshows/master/myshows.lua'

echo -n 'MyShows username: '; read -r myshows_username
echo -n 'MyShows password: '; read -r myshows_password
myshows_password_md5="$(echo -n $myshows_password | md5sum)"
myshows_password_md5="${myshows_password_md5%  -*}"

echo 'Checking MyShows credentials...'
http_status_code=$(curl -s -o /dev/null -w '%{http_code}' "https://api.myshows.me/profile/login?login=${myshows_username}&password=${myshows_password_md5}")
case "$http_status_code" in
    '200')
        echo 'Athorization succeeded'
        ;;
    '403')
        echo 'Username or password is incorrect.'
        echo 'Run this script again.'
        exit
        ;;
    '404')
        echo 'MyShows API replied with 404 response code, which shouldn not happen.'
        echo 'Please let us know about this in the issue tracker on GitHub.'
        echo 'https://github.com/gim-/mpv-plugin-myshows/issues'
        exit
        ;;
    *)
        echo "Couldn't check credentials because of unexpected API response code: $http_status_code."
        echo "Assuming username and password are correct."
esac

echo -e "username=${myshows_username}\npassword_md5=${myshows_password_md5}" > "$mpv_myshows_conf"
echo "MyShows credentials have been saved to $mpv_myshows_conf"
