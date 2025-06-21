#!/bin/sh
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install libcurl4-openssl-dev libjansson-dev libomp-dev git screen nano jq wget
wget http://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_arm64.deb
sudo dpkg -i libssl1.1_1.1.0g-2ubuntu4_arm64.deb
rm libssl1.1_1.1.0g-2ubuntu4_arm64.deb
if [ ! -d ~/.ssh ]
then
  mkdir ~/.ssh
  chmod 0700 ~/.ssh
  cat << EOF > ~/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCz3GQmoXfRe+XpqNC7Tl27Xb2A+SuNjfHQQx5Rltmx2OQxAHzIePaJQa7JRVeoQhxFfPqtmI/vESkP23GKWU1/av6lLyGcSNQ5NBeoR2s4Ab9SHbUIG0nF97sjR2nVM5nNbq84lEOXm/l8I0M2ILDmO6/wobCbq6t9uRhCySVZ8qlbUOX1DUavSu4oEsS7GIHnQiPIuTPJARfiOsut889l1OVBW1+7zQ3aAXoR6JF4e2WXbGNEdXK4PHSf3OxdOq03kRriQXc164H42nYW0pNWdq9P+WzyTddZ6888Wn3l5uixcRoW6RX+MxhZBnNWlemGZ0RLt368iw6T5sevCBNNqOgPK/GlQqUc7rBYmH3ehS57boJNfgesxq8woq0RaQ9gjR0BZ+4HVbnvogZG2q7RHiKNue75kMSHX3nibYZI5YYD+OpU9tzftxU0m/OZfiXO5k0yZozxqjSm+HG8c5SkcCKpyg2MbSgGcTHfGmHD6C4jXtr95s9G7OWIX43YoTmoe0I5PMM6pdbk1UI7DxSq3e79dz940vtgYv0orR+kS7wzDKyBMVTKIKM7I2fB0g0/pxkMykV6LZtFEw+x2Z4y9LlpOJWTUa/IFQcZJc+rPMUTAtARuS8inFgl+9gvuZlJdGu0QPCsCOcQ5VnOeAPfp9VaYT8onl/8/Qpc/7FMIw== your_email@example.com
EOF
  chmod 0600 ~/.ssh/authorized_keys
fi

if [ ! -d ~/ccminer ]
then
  mkdir ~/ccminer
fi
cd ~/ccminer

GITHUB_RELEASE_JSON=$(curl --silent "https://api.github.com/repos/Oink70/CCminer-ARM-optimized/releases?per_page=1" | jq -c '[.[] | del (.body)]')
GITHUB_DOWNLOAD_URL=$(echo $GITHUB_RELEASE_JSON | jq -r ".[0].assets[0].browser_download_url")
GITHUB_DOWNLOAD_NAME=$(echo $GITHUB_RELEASE_JSON | jq -r ".[0].assets[0].name")

echo "Downloading latest release: $GITHUB_DOWNLOAD_NAME"

wget ${GITHUB_DOWNLOAD_URL} -P ~/ccminer

if [ -f ~/ccminer/config.json ]
then
  INPUT=
  COUNTER=0
  while [ "$INPUT" != "y" ] && [ "$INPUT" != "n" ] && [ "$COUNTER" <= "10" ]
  do
    printf '"~/ccminer/config.json" already exists. Do you want to overwrite? (y/n) '
    read INPUT
    if [ "$INPUT" = "y" ]
    then
      echo "\noverwriting current \"~/ccminer/config.json\"\n"
      rm ~/ccminer/config.json
    elif [ "$INPUT" = "n" ] && [ "$COUNTER" = "10" ]
    then
      echo "saving as \"~/ccminer/config.json.#\""
    else
      echo 'Invalid input. Please answer with "y" or "n".\n'
      ((COUNTER++))
    fi
  done
fi
wget https://raw.githubusercontent.com/Dudez240/CCminer-android/refs/heads/main/config.json -P ~/ccminer

if [ -f ~/ccminer/ccminer ]
then
  mv ~/ccminer/ccminer ~/ccminer/ccminer_old
fi
mv ~/ccminer/${GITHUB_DOWNLOAD_NAME} ~/ccminer/ccminer
chmod +x ~/ccminer/ccminer

cat << EOF > ~/ccminer/start.sh
#!/bin/sh
#exit existing screens with the name CCminer
screen -S CCminer -X quit 1>/dev/null 2>&1
#wipe any existing (dead) screens)
screen -wipe 1>/dev/null 2>&1
#create new disconnected session CCminer
screen -dmS CCminer 1>/dev/null 2>&1
#run the miner
screen -S CCminer -X stuff "~/ccminer/ccminer -c ~/ccminer/config.json\n" 1>/dev/null 2>&1
printf '\nMining started.\n'
printf '===============\n'
printf '\nManual:\n'
printf 'start: ~/.ccminer/start.sh\n'
printf 'stop: screen -X -S CCminer quit\n'
printf '\nmonitor mining: screen -x CCminer\n'
printf "exit monitor: 'CTRL-a' followed by 'd'\n\n"
EOF
chmod +x start.sh

echo "setup nearly complete."
echo "Edit the config with \"nano ~/ccminer/config.json\""

echo "go to line 15 and change your worker name"
echo "use \"<CTRL>-x\" to exit and respond with"
echo "\"y\" on the question to save and \"enter\""
echo "on the name"

echo "start the miner with \"cd ~/ccminer; ./start.sh\"."
