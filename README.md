# MyShows episode mark as watched

This user script will automatically find out which TV show and episode you're watching right now and mark it as watched on [MyShows](https://myshows.me) when you've watched 3/4 of the video file duration. You can also mark it manually by pressing a hotkey.

# Dependencies

This plugin uses [luasocket](https://github.com/diegonehab/luasocket) and [luasec](https://github.com/brunoos/luasec). In some cases you might need to install them separately.

## Ubuntu/Debian

`sudo apt-get install lua-socket`

## Arch Linux

`pacman -S lua52-socket`

## Mac OS X

```bash
sudo luarocks --lua-version 5.1 --tree /usr/local/ install luasocket
brew install openssl
sudo luarocks --lua-version 5.1 --tree /usr/local/ install luasec OPENSSL_DIR=/opt/homebrew/opt/openssl@3
```

# Installation

## Automatically

Download the `install.sh` shell script and launch it.
```Bash
wget https://raw.githubusercontent.com/gim-/mpv-plugin-myshows/master/install.sh
sh install.sh
```
It will automatically download the user script and then ask you for your MyShows credentials. After you get the message `MyShows credentials have been saved` you're good to go.

## Manually

Download and put the `myshows.lua` file in your scripts configuration subdirectory (usually `~/.config/mpv/scripts/`).
```Bash
mkdir -p ~/.config/mpv/scripts/
cd ~/config/mpv/scripts
wget https://raw.githubusercontent.com/gim-/mpv-plugin-myshows/master/myshows.lua
```
Then create a configuration file named `myshows.conf` in your Lua settings configuration subdirectory (usually `~/.config/mpv/lua-settings`) that contains your MyShows credentials (username and MD5 hashed password)
```Bash
mkdir -p ~/.config/mpv/lua-settings/
cd ~/.config/mpv/lua-settings/
# Substitude USERNAME and PASSWORD in the following statement with your MyShows credentials.
echo -e "username=USERNAME\npassword_md5=${$(echo -n 'PASSWORD' | md5sum)%  -*}" > ~/.config/mpv/lua-settings/myshows.conf
```
`myshows.conf` should look like this:
```
username=demo239
password_md5=0f25bd0ff7b9cfd3ebbec99f55a34b61
```
That's it, you're good to go.

# Usage

Episode marking should be done automatically after you watch 3/4 of the video file duration. Though you can do it manually too by pressing 'myshows_mark' (default: W (capital w)) hotkey. If you want to change hotkey to something else you can do this by adding `KEYNAME script_binding myshows_mark` in to your `input.conf`.

For example, if you want to set it to B (capital b):
```Bash
mkdir -p ~/.config/mpv/
echo 'B script_binding myshows_mark' >> ~/.config/mpv/input.conf
```

# Known issues

* MyShows API in some cases can't find episode information based on even very descriptive file name, which results in episode not being marked.
