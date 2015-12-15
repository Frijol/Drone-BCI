from dronekit import *
from dronedirect import DroneDirect

SIM = False
running = True

print "connecting to drone..."
if SIM:
    vehicle = connect('127.0.0.1:14551', wait_ready=True)
else:
    vehicle = connect('0.0.0.0:14550', wait_ready=True) # connecting from GCS
    #vehicle = connect('udpout:127.0.0.1:14560', wait_ready=True) #connecting from onboard solo


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
        # dd.enable_fence(self, alt_floor, alt_ceiling ,radius)
        dd.translate(x=1)

finally:
    dd.release()
