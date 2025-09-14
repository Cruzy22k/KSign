# Ksign kernel signing tool. WIP
## A tool for signing kernels.

## Purpose of this script
This script automates the signing of kernels, that are not signed by Microsofts signing key. This is particulary useful if you run a standard linux installation, but run a custom kernel such as the Cachyos kernel. It saves time by automating the signing of the kernels each update.


## Prerequisites
To run this script, make sure that you have the following dependencies installed.
- Both your MOK key and cert, located in `/root/mok`. (See below for setup instructions.)
- `sbsign`
- `sbverify`
- An internet connection.
- A brain (optional)
-----

## Usage

Run the script in interactive mode:

```
curl -LO https://raw.githubusercontent.com/Cruzy22k/KSign/main/ksign.sh
sudo bash ksign.sh
```
Follow the prompts to select the kernel to sign. 

### Options:
- `ksign.sh -a` to enable automated mode, which signs every kernel in `/boot`
- `ksign.sh -h` for help using the tool

## Automation

You can use Ksign automatically once per day after login. There are two recommended methods.

1. Using Cron (Simpler)

Download the automated script:

```
cd /root
# Download the automated KSign script
curl -LO https://raw.githubusercontent.com/Cruzy22k/KSign/main/cron_ksign.sh
chmod +x cron_ksign.sh
```
and edit the root crontab with:
```
sudo crontab -e
```
Append this line to run the script after boot.
`@reboot /root/cron_ksign.sh`
The script will only sign unsigned kernels once per day and skips the currently running kernel. Logs are written to `/var/log/ksign.log`.


2. Using Systemd Timer (Recommended, more complicated to setup.)
- Create a user service file:
```
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/ksign.service

```

- Paste this into it:
```
[Unit]
Description=Sign kernels once a day after login
After=graphical.target

[Service]
Type=oneshot
ExecStart=/root/cron_ksign.sh

[Install]
WantedBy=default.target
```
Save and exit (`Ctrl+O`, `Ctrl+X`).
- Create the timer file: 
```
nano ~/.config/systemd/user/ksign.timer
```
- Paste this into it:
```
[Unit]
Description=Run KSign once per day

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```
Save and exit (`Ctrl+O`, `Ctrl+X`).

Enable and start the timer with:
```
systemctl --user enable --now ksign.timer
```
> [!NOTE]  
> This method is more robust than cron, integrates with systemd logging, and ensures KSign runs once per day automatically.

> [!NOTE]
>Both methods prevent signing the currently running kernel and keep logs in /var/log/ksign.log.
----
### Setting up a MOK Key. (if not already done.)

- 1: 
    Generate a new key and certificate.
    ```
    sudo mkdir -p /root/mok
    cd /root/mok
    sudo openssl req -new -x509 -newkey rsa:2048 -keyout MOK.key -out MOK.crt -nodes -days 36500 -subj "/CN=CustomSigningKey/"
    ```
- 2:
    Enroll the key into the bios.
    ```
    sudo mokutil --import /root/mok/MOK.crt
    ```
    This command will give you a prompt to enter a password of your choosing.
    Remember the password you set as you will need it in the next step.

> [!NOTE]  
> You may need to install mokutil from your package manager
- 3: 
    Reboot and follow the MOK manager prompts to enroll the custom signing key with the password you set.
- 4:
    This is a one time only thing, you won't need to do this another time, the script will handle all the signing using that key.


----
Made with ♡ by Cruzy

Pull requests welcome with fixes. 
