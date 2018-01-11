#!/usr/bin/python

import thread
import time

# Define a function for the thread
def print_time( threadName, delay):
   count = 0
   while count < 5:
      # time.sleep(delay)
      c=0
      for i in range(delay*100000):
         a=2+c
         c=c+a
         b=2+c
         c=c+b
      count += 1
      print "%s: %s" % ( threadName, time.ctime(time.time()) )

# Create two threads as follows
try:
   thread.start_new_thread( print_time, ("Thread-1", 2, ) )
   thread.start_new_thread( print_time, ("Thread-2", 4, ) )
   thread.start_new_thread( print_time, ("Thread-3", 2, ) )
   thread.start_new_thread( print_time, ("Thread-4", 4, ) )
   thread.start_new_thread( print_time, ("Thread-5", 2, ) )
   thread.start_new_thread( print_time, ("Thread-6", 4, ) )
   thread.start_new_thread( print_time, ("Thread-7", 2, ) )
   thread.start_new_thread( print_time, ("Thread-8", 4, ) )
except:
   print "Error: unable to start thread"

# print "Done"
while 1:
   pass