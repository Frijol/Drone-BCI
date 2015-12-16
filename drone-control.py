# Libraries for drone control
from dronekit import *
from dronedirect import DroneDirect

# Libraries for UDS socket
import socket
import sys
import math
import json

# Create a UDS socket
sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

# Connect the socket to the port where the server is listening
server_address = '/tmp/bci-data.sock'
print >>sys.stderr, 'Connecting to %s' % server_address
try:
    sock.connect(server_address)
except socket.error, msg:
    print >>sys.stderr, msg
    sys.exit(1)

# Initial setup vars for drone
SIM = True
running = True
data_string = ''
packet_depth = 0
takeoff = False # it has not yet taken off

# Connect to drone
print 'Connecting to drone...'
if SIM:
    vehicle = connect('tcp:127.0.0.1:5760', wait_ready=True)
else:
    vehicle = connect('0.0.0.0:14550', wait_ready=True) # connecting from GCS
    #vehicle = connect('udpout:127.0.0.1:14560', wait_ready=True) #connecting from onboard solo

# Take control of the drone
dd = DroneDirect(vehicle)
dd.take_control()

if SIM:
    #arm and takeoff drone - DO NOT USE THIS ON A REAL DRONE ONLY IN SIMULATION
    if vehicle.armed == False:
        # Don't let the user try to arm until autopilot is ready
        print 'Waiting for vehicle to initialise...'
        while not vehicle.is_armable:
            time.sleep(1)
        vehicle.armed   = True
        print 'Vehicle Armed'
    dd.takeoff()

try:
    while running:
        # Listen for data
        data = sock.recv(16)

        # Turn data into nice JSON packages
        for i in data:
            if i == '{':
                packet_depth = packet_depth + 1
            elif i == '}':
                packet_depth = packet_depth - 1

            data_string += i

            if packet_depth == 0:
                # Parse JSON
                packet = json.loads(data_string)
                # Set up appropriate action
                x = 0
                y = 0
                z = 0
                if packet['action'] == 'xval':
                    x = packet['power']
                elif packet['action'] == 'pull':
                    # y = math.floor(float(packet['power'] * 10))
                    y = 3
                elif packet['action'] == 'push':
                    # z = packet['power']
                    z = 3;
                elif packet['action'] == 'neutral':
                    data_string = ''
                    continue
                else:
                    print 'Unmapped action: "%s"' % packet['action']
                # Move the copter accordingly
                if not takeoff:
                    dd.takeoff(altitude_meters=15)
                    takeoff = True
                else:
                    dd.translate(x=x, y=y, z=z)
                # Reset for next JSON packet
                data_string = ''

finally:
    dd.release()
