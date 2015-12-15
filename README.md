# Drone-BCI
Controlling a drone with brain control
Most of this project is adapted from DroneDirect: https://github.com/djnugent/dronedirect

## Run instructions

### Setting up your Solo development environment

1. Install solo-cli with `pip install -UI git+https://github.com/3drobotics/solo-cli` (you may need sudo for pip installs)
1. Install virtualenv with `pip install virtualenv`

### Preparing your directory

1. Git clone this directory, then navigate to it in your terminal
1. Run `sudo pip install -r requirements.txt` to install dependencies

### Running code on Solo

1. Run `solo script pack` while connected to the internet to bundle your script
1. Turn on your Solo and connect to its Wifi from your computer
1. Run `solo script run <myscript.py>`
