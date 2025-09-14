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

To use this script, run the following command on your device.

```
curl -LO https://raw.githubusercontent.com/Cruzy22k/KSign/main/ksign.sh && sudo bash ksign.sh
```

Follow the prompts to select the kernel to sign. 
### Options:
- `ksign.sh -a` to enable automated mode, which signs every kernel in `/boot`
- `ksign.sh -h` for help using the tool


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
