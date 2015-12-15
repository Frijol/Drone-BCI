# Libraries for drone control
from dronekit import *
from dronedirect import DroneDirect

# Libraries for UDS socket
import socket
import sys

# Create a UDS socket
sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

# Connect the socket to the port where the server is listening
server_address = './tmp/bci-data.sock'
print >>sys.stderr, 'connecting to %s' % server_address
try:
    sock.connect(server_address)
except socket.error, msg:
    print >>sys.stderr, msg
    sys.exit(1)

# Initial setup vars for drone
SIM = False
running = True

# Connect to drone
print "connecting to drone..."
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
        print " Waiting for vehicle to initialise..."
        while not vehicle.is_armable:
            time.sleep(1)
        vehicle.armed   = True
        print 'Vehicle Armed'
    dd.takeoff()

try:
    while running:
        # Set up geofence
        dd.enable_fence(alt_floor=50, alt_ceiling=100 , radius=10)

        # Listen for data
        data = sock.recv(16)
        amount_received += len(data)
        # Print the data
        print >>sys.stderr, 'received "%s"' % data

        # Move the copter
        dd.translate(x=1)

finally:
    dd.release()
