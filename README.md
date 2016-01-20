# MyShows episode mark as watched

This user script will automatically find out which TV show and episode you're watching right now and mark it as watched on [MyShows](https://myshows.me) when you've watched 3/4 of the video file duration. You can also mark it manually by pressing a hotkey.

# Installation

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
username=MyUserName
password_md5=319f4d26e3c536b5dd871bb2c52e3178
```
That's it, you're good to go.

# Usage

Episode marking should be done automatically after you watch 3/4 of the video file duration. Though you can do it manually too by pressing 'myshows_mark' (default: W (capital w!)) hotkey. If you want to change hotkey to something else you can do this by adding `KEYNAME script_binding myshows_mark` in to your `input.conf`.

For example, if you want to set it to B (capital b):
```Bash
mkdir -p ~/.config/mpv/
echo 'B script_binding myshows_mark' >> ~/.config/mpv/input.conf
```

# Known issues

* MyShows API in some cases can't find episode information based on even very descriptive file name, which results in episode not being marked. Currently I'm working on it.

# Disclaimer

This software is provided as-is, without any warranties.
