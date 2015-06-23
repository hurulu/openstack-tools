#!/usr/bin/env python

import sys,string
import os
import MySQLdb as mdb

compute_list = "("
fp = open("compute_nodes","r")
for line in fp.readlines():
	compute_list = compute_list + "'" + line.rstrip('\n') + "'" + ","
fp.close()
compute_list = compute_list.rstrip(',') + ")"

#print compute_list


try:
    con = mdb.connect('mysql-server', 'nova', 'novapassword', 'nova');
    cur = con.cursor()
    cur.execute("select uuid,host,launched_on,deleted from instances where host in "+str(compute_list)+"and deleted=0")

    result = cur.fetchall()
    for i in result:
	print i[0]
    
#   print len(result)
except mdb.Error, e:
  
    print "Error %d: %s" % (e.args[0],e.args[1])
    sys.exit(1)
    
finally:    
        
    if con:    
        con.close()
