# Drone-BCI
Controlling a drone with brain control. Aka awakening the force, or telekinesis.

![](https://cloud.githubusercontent.com/assets/454690/11829632/c33ade64-a352-11e5-8255-7d1f55cadbe5.png)
[first test flight](https://youtu.be/blZMIsAUTwo)

Note: works on OSX

## Materials

* [Emotiv EPOC headset](https://store.3drobotics.com/products/solo)
* [3DR Solo drone](https://store.3drobotics.com/products/solo)

## Set up and run

### Server-side
1. Put on your Emotiv headset and ensure it's connected
1. Open the project in XCode (`open OSX_Project/MentalCommand/MentalCommand.xcodeproj`) and hit CMD + R to build and run

### Client-side
1. Git clone this directory, then navigate to it in your terminal
1. Run `sudo pip install -r requirements.txt` to install dependencies
1. Run `python setup.py install` to install local dependencies
1. Turn on Solo and controller, and connect your computer to its Wifi
1. Run `python drone-control.py`

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

We then sent actions over the server-side UDS from the Mac app (Emotiv-side) packaged as JSON, and parsed the incoming JSON into actions on the client (drone) side.

## Useful links

* [Solo Developer Guide](http://dev.3dr.com/)
* [DroneDirect repo](https://github.com/djnugent/dronedirect)
* [About Unix Domain Sockets (UDS)](https://pymotw.com/2/socket/uds.html)
* [Emotiv Community SDK](https://github.com/Emotiv/community-sdk)
* [Emotiv Objective-C Example](https://github.com/Emotiv/community-sdk/blob/master/examples/ObjectiveC/Mac%20OS/MentalCommand/MentalCommand/EngineWidget.mm)

## Credit where credit is due
Much of the drone control piece of this project is adapted from DroneDirect: https://github.com/djnugent/dronedirect
