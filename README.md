# L2JMobius-on-rpi
This repository contains bootstrap files to easily install L2JMobius server on your Raspberry Pi 4B **8Gb**

If you like any part of this repository, please consider to:
- Donate to L2J Mobius.
- Leave a star on this repository.

## Prerequisites

Basically, you will need linux distribution running on supported architecture with git and docker installed.

- `Linux` - probably any modern distribution will do. To create the setup I used Arch btw™, and to test it - Raspberry Pi OS on Raspberry Pi 4 with **8Gb of RAM**.
- `Git` - you probably already know what this is. If you don't, check if you have it installed already by typing `git -v`, and if you see something like `git version *.*.*`, you are good to go. If not, consult Google on how to install `git` for your linux distribution.
- `Docker` - you will need `docker`, `docker compose` (v2), and `docker build` (buildx) available without `sudo`. If you prefer to have it available only through `sudo`, you'll need to edit `install.sh` and add sudo before each docker-related command. Also, notice that it may lead to various problems with volume permissions. Anyway, consult official website for docker install instructions.
- Supported architectures - these include architectures provided by Alpine Linux packages (`apache-ant`, `openjdk17-jre-headless`, and `unzip`). Currently (early 2023) the least represented package is `openjdk17-jre-headless` available only on `x86_64`, `aarch64`, and `s390x`. Raspberry Pi Os (64-bit) runs on aarch64. Your regular desktop linux - probably on x86_64.

Feel free to clone and tinker, and come back into issues with your findings, or just message me anywhere.

## Install instructions

Warning: This instructions involve some repository juggling, please read carefully.

1. Clone **THIS** repository.
1. Read through Mobius' instructions for W64, but don't do anything yet. This is just so you know where's what. The only thing you'll actually need from Mobius' instructions for now is server repository link.
1. Clone L2JMobius server repository. You should end up with a bunch of folders inside it, like `Account_Manager`, `L2J_Mobius_01.0_Ertheia`, etc. Make your mind about what server do you want and copy that server files into `./services/l2jmobius/src/` directory, so `build.xml` ends up being in `./services/l2jmobius/src/`
1. Read through the `readme.txt`, and download related geodata file into `./services/l2jmobius/geodata/` directory of **THIS** repository. The structure should end up looking like this:

```
./
├── services/
│   ├── l2jmobius/
│   │   ├── geodata/
│   │   │   └── downloaded_geodata_archive.zip
│   │   ├── src/
│   │   │   ├── ...
│   │   │   ├── build.xml
│   │   │   └── readme.txt
│   │   ├── build-entrypoint.sh
│   │   ├── builder.Dockerfile
│   │   ├── game.Dockerfile
│   │   └── login.Dockerfile
│   ├── mariadb/
│   └── phpmyadmin/
├── docker-compose.yml
├── install.sh
└── README.md <~ You are here
```

1. If you want to edit server settings, now is the time. Game server configs are in `./services/l2jmobius/src/dist/game/config` directory, login server configs are in `/.services/l2jmobius/src/dist/login/config` directory. Backing these up is a good idea too. Do not edit database url, database user and database password in Server.ini and LoginServer.ini files! These are edited via `install.sh` script later.
1. Edit `./services/build-entrypoint.sh`, most important thing it contains is an example of ipconfig.xml, a file that makes your game server available on specified hosts other than localhost. As far as I can tell, this file is responsible for IPs your login server tells your client to try to connect to when you see game server list after logging in. If ipconfig.xml contains only default values (from `default-ipconfig.xml`) or is misconfigured, your client will not be able to connect to your game server. My default values are for my own setup, in which my Raspberry Pi has static IP address (`192.168.1.2`). If you want to use the default-ipconfig.xml (i.e. your intent is just to play on localhost), remove these lines (starting from cat, up to EOM)
1. Edit `./.env` file in the root of **THIS** repository. It must contain MARIADB_USER, MARIADB_PASSWORD, MARIADB_ROOT_USER, and any or no value for MARIADB_DATABASE:
```
MARIADB_USER=l2j_db_user
MARIADB_PASSWORD=l2j_db_password
MARIADB_ROOT_PASSWORD=l2j_root_password
MARIADB_DATABASE=
```

1. Now we can try to bring this all together^
```bash
./install.sh
```
You'll have to wait some time, if it hands for more than 15 minutes on your Raspberry Pi, just `Ctrl+C` and restart it. Nothing irreversibly bad will happen.
Next thing you want to do is set up your client and go play! Congrats!

## PS

If you like any part of this repository, please consider to:

- Donate to L2J Mobius.
- Leave a star on this repository.

Cheers!
