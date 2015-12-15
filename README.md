# Drone-BCI
Controlling a drone with brain control.

Much of this project is adapted from DroneDirect: https://github.com/djnugent/dronedirect

## Dev setup instructions

### Setting up your Solo development environment

1. Install solo-cli with `pip install -UI git+https://github.com/3drobotics/solo-cli` (you may need sudo for pip installs)
1. Install virtualenv with `pip install virtualenv`

### Preparing your directory

1. Git clone this directory, then navigate to it in your terminal
1. Run `sudo pip install -r requirements.txt` to install dependencies
1. Run `python setup.py install` to install local dependencies

### If you want a SITL aka virtual Solo

Get one [here](https://github.com/dronekit/dronekit-sitl)

### Running code on Solo

1. Run `solo script pack` while connected to the internet to bundle your script
1. Turn on your Solo and connect to its Wifi from your computer
1. Run `solo script run <myscript.py>`

## Process of making this

### Figure out how to talk to Solo

Try out the [DroneDirect repo](https://github.com/djnugent/dronedirect) and ensure you can talk to/direct a Solo from there.

The `template.py` file in the Examples folder is a great place to start. Run it locally, and put some commands in the "your code here" section.

If you're looking for commands, they're well documented in dronedirect/__init__.py of this repo.

### Figure out how to get what you need from the Emotiv headset

We used this [Emotiv Objective-C Example](https://github.com/Emotiv/community-sdk/blob/master/examples/ObjectiveC/Mac%20OS/MentalCommand/MentalCommand/EngineWidget.mm)

### Set up a UDS

[This tutorial for the Python side](https://pymotw.com/2/socket/uds.html) makes this pretty easy. Test server/client to make sure it works, then integrate the client side into the main Python code.


## Useful links

* [Solo Developer Guide](http://dev.3dr.com/)
* [DroneDirect repo](https://github.com/djnugent/dronedirect)
* [About Unix Domain Sockets (UDS)](https://pymotw.com/2/socket/uds.html)
* [Emotiv Community SDK](https://github.com/Emotiv/community-sdk)
* [Emotiv Objective-C Example](https://github.com/Emotiv/community-sdk/blob/master/examples/ObjectiveC/Mac%20OS/MentalCommand/MentalCommand/EngineWidget.mm)
