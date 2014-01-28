#@Author: Shivanshu Goyal
#Student Number: 33245127
#Date: January 27, 2014
#Lab 3 - SPI and Data Logging using Python

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import sys, time, math, serial

xsize=100

ser = serial.Serial( 
 port='COM3', 
 baudrate=115200, 
 parity=serial.PARITY_NONE, 
 stopbits=serial.STOPBITS_TWO, 
 bytesize=serial.EIGHTBITS, 
)
ser.isOpen() 


def data_gen():
    t = data_gen.t
    while True:
       t+=1
       val=ser.readline() 
       yield t, val

def run(data):
    # update the data
    t,y = data
    if t>-1:
        xdata.append(t)
        ydata.append(y)
        if t>xsize: # Scroll to the left.
            ax.set_xlim(t-xsize, t)
        line.set_data(xdata, ydata)

    return line,

def on_close_figure(event):
    sys.exit(0)

data_gen.t = -1
fig = plt.figure()
fig.canvas.mpl_connect('close_event', on_close_figure)
ax = fig.add_subplot(111)
line, = ax.plot([], [], lw=2)
ax.set_ylim(-40, 100)
ax.set_xlim(0, xsize)
ax.grid()
xdata, ydata = [], []

# Important: Although blit=True makes graphing faster, we need blit=False to prevent
# spurious lines to appear when resizing the stripchart.
ani = animation.FuncAnimation(fig, run, data_gen, blit=False, interval=100, repeat=False)
plt.show()
