#!/usr/bin/python

import threading
import time

exitFlag = 0

class myThread (threading.Thread):
   def __init__(self, threadID, name, counter):
      threading.Thread.__init__(self)
      self.threadID = threadID
      self.name = name
      self.counter = counter
      
   def run(self):
      print "Starting " + self.name
      print_time(self.name, 5, self.counter*10)
      print "Exiting " + self.name

def print_time(threadName, counter, delay):
   while counter:
      if exitFlag:
         threadName.exit()
      time.sleep(delay)
      n=1
      for i in range(1,delay*100):
        n = n+i
      
      print "%s: %s, result:%i" % (threadName, time.ctime(time.time()),n)
      counter -= 1

threadList=[]

# Create new threads
thread1 = myThread(1, "Thread-1", 1)
thread2 = myThread(2, "Thread-2", 2)
thread3 = myThread(3, "Thread-3", 2)
thread4 = myThread(4, "Thread-4", 4)
thread5 = myThread(5, "Thread-5", 3)
thread6 = myThread(6, "Thread-6", 6)
thread7 = myThread(7, "Thread-7", 4)
thread8 = myThread(8, "Thread-8", 8)

# Start new Threads
thread1.start()
thread2.start()
thread3.start()
thread4.start()
thread5.start()
thread6.start()
thread7.start()
thread8.start()

# Add threads to thread list
threadList.append(thread1)
threadList.append(thread2)
threadList.append(thread3)
threadList.append(thread4)
threadList.append(thread5)
threadList.append(thread6)
threadList.append(thread7)
threadList.append(thread8)

# Wait for all threads to complete
for t in threadList:
    t.join()

print "Exiting Main Thread"