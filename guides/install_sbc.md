# Installing Exshome on a Single Board Computer (SBC)

This guide was tested against Desktop Rasbperry PI OS on Rasbperry PI 3 A+ and should work for similar setup.

## Installing system dependencies

Let's install system Exshome dependencies:
- MPV - Exshome uses it as a music player.

```
sudo apt update
sudo apt install mpv
```

## Installing Elixir and Erlang

If your SBC has enough resources (at least 1 GB of RAM), you can try compiling Erlang from sources via [asdf](https://asdf-vm.com/guide/getting-started.html).
Make sure that you have installed [all dependencies for building erlang](https://github.com/asdf-vm/asdf-erlang#before-asdf-install).
```
asdf plugin add erlang
asdf install erlang 26.0.2
asdf global erlang 26.0.2
```

Otherwise you can install Erlang with your package manager. It may be not the latest version, but it should work.
```
sudo apt install erlang
```

We can install the latest Elixir version with [asdf](https://asdf-vm.com/guide/getting-started.html):
```
asdf plugin add elixir
asdf install elixir 1.15.4-otp-26
asdf global elixir 1.15.4-otp-26
```

## Installing Exshome

Install Exshome itself
```
wget https://raw.githubusercontent.com/exshome/exshome/main/bin/exshome
chmod +x exshome
./exshome
```

You can reach Exshome at [`http://raspberrypi.local:5000`](http://raspberrypi.local:5000).

## Creating autostart scripts

You can start the script automatically together with the system.

Create the file `/etc/systemd/system/exshome.service` with these contents:

```
[Unit]
Description=Exshome - DIY Elixir Smart Home

[Install]
WantedBy=multi-user.target

[Service]
Environment="XDG_RUNTIME_DIR=/run/user/1000"
Environment="PULSE_RUNTIME_PATH=/run/user/1000/pulse/"
User=pi
Group=pi
Type=simple
WorkingDirectory=/home/pi/
ExecStart=/bin/bash -lic "./exshome || exit $?"
Restart=always
RemainAfterExit=true
RestartSec=10s
```

You can adjust this file to match your setup.

The next commands help to start application:

```
sudo systemctl daemon-reload
sudo systemctl start exshome.service
```

You can start Exshome automatically on system start:
```
sudo systemctl enable exshome.service
```

This command allows you to see the logs of a service:
```
journalctl -fu exshome.service
```

## Launching browser on system start

Create a file `~/.config/autostart/exshome.desktop`. For example:
```
mkdir ~/.config/autostart
nano ~/.config/autostart/exshome.desktop
```

Fill it with these contents:
```
[Desktop Entry]
Type=Application
Name=Exshome
Exec=bash -c "while ! curl -f -LI http://localhost:5000 ; do sleep 10; done; chromium-browser --start-fullscreen --kiosk --incognito --noerrdialogs --disable-translate --no-first-run --fast --fast-start --disable-infobars --disable-features=TranslateUI --disk-cache-dir=/dev/null  --password-store=basic --disable-pinch --overscroll-history-navigation=disabled --disable-features=TouchpadOverscrollHistoryNavigation http://localhost:5000?setTheme=dark"
StartupNotify=false
Terminal=false
```

You may need to refresh a page with `Ctrl+R` or `F5`, if it shows a blank page.

You can play with `Exec` option here and see what works for you.
For example, deleting `--incognito` switch will allow to keep theme settings.

## Troubleshooting

- If you have missing emoji on Raspberry PI, you can install fonts that support it:
```
sudo apt install fonts-noto-color-emoji
```
- If your screen becomes blank. You can disable screen blanking on Raspberry PI via `raspi-config` in `Display Options > Screen Blanking`.
