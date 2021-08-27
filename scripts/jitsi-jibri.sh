#!/bin/sh

# https://github.com/jitsi/jibri
# https://community.jitsi.org/t/tutorial-how-to-install-the-new-jibri/88861

echo "Unable to install Jibri due to unresolved issue, see: https://github.com/jitsi/jibri/issues/423"
exit 1

if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo "Please run the script as root!"
    exit 1
fi

# require environment variables
if [[ -z ${DOMAIN} || -z ${EMAIL} || -z ${CF_API_TOKEN} || -z ${PUBLIC_IPv4} || -z ${AUTH_DOMAIN} || -z ${ISSUER_BASE_URL} || -z ${CLIENT_SECRET} ]]; then
    echo "Missing environemnt variables, check docs!"
    exit 1
fi

# stop execution on failure
set -e

# configure alsa loopback module
echo "snd-aloop" >> /etc/modules
modprobe snd-aloop
lsmod | grep snd_aloop

# install google chrome
curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/google-keyring.gpg'
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
apt-get -y update
apt-get -y install google-chrome-stable

# adjust policies
mkdir -p /etc/opt/chrome/policies/managed
echo '{ "CommandLineFlagSecurityWarningsEnabled": false }' >> /etc/opt/chrome/policies/managed/managed_policies.json

# install google chromedriver
CHROME_DRIVER_VERSION=$(curl -fsSL chromedriver.storage.googleapis.com/LATEST_RELEASE)
wget -N http://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip -P ~/
unzip ~/chromedriver_linux64.zip -d ~/
rm ~/chromedriver_linux64.zip
sudo mv -f ~/chromedriver /usr/local/bin/chromedriver
sudo chown root:root /usr/local/bin/chromedriver
sudo chmod 0755 /usr/local/bin/chromedriver

apt-get -y install default-jre-headless ffmpeg curl alsa-utils icewm xdotool xserver-xorg-video-dummy

#apt install -y jibri
# see https://github.com/jitsi/jibri/issues/423
