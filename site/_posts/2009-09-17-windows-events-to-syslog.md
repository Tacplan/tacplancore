---
layout: post
title: Sending Windows Events To A SysLog Server
date: 2009-09-17 20:33
tags:
- syslog
- windows
- events
- swatch
- logs
---
**SENDING WINDOWS EVENTS TO A SYSLOG SERVER**

######{i}This post was migrated over from my old blog at [Blogspot](http://www.blogspot.com){/i}

Many of us know and love (or hate) syslog and syslog-ng for UNIX based operating systems.  The ability to collect and monitor all UNIX based system logs in a centralized repository has been a standard feature of UNIX systems for ages now.  This is great, if all you have are UNIX or Linux systems.  
After much trial and error, I have found what I believe to be the simplest and most cost-effective method of deploying centralized logging for Windows systems.  I have documented everything here as best as I can remember.

You will need the following:
Windows systems that you want to get log data from
A syslog server to send the data to
The "Eventlog to Syslog" utility

If you already have a syslog server, and are just here to get your Windows server reporting to it, then proceed to the EVENTLOG TO SYSLOG UTILITY section.
If you simply want the deployment script, check out the DEPLOYMENT SCRIPT section.
If you don't have a syslog server yet, you can follow my directions in the SYSLOG SERVER section or use any of the instructions out there on the web.
If you are just here to configure swatch, check out the SWATCH CONFIGURATION section.
If you're here for the whole lot, then read on from this point.

<br />

**EVENTLOG TO SYSLOG UTILITY**

The good folks at Purdue University have written and fully documented a wonderfully simple app called, "Eventlog to Syslog".  They have written it for both 32-bit and 64-bit Windows systems, and even provided the source code.  Oh, and it's free.

You can find the project page for this app here:  https://engineering.purdue.edu/ECN/Resources/Documents/UNIX/evtsys/

I recommend downloading all available files for posterity- You never know if and when they will stop providing access to this utility.  I created a hidden network share that contains all installation files and documentation for this utility, as well as the deployment/update scripts.  I will, of course, be sharing these scripts as well.

To manually install the utility: 
Uncompress "evtsys.DLL" and "evtsys.exe" to %systemroot%\system32.
At a command prompt, enter "%systemroot\system32\evtsys.exe -i -h hostname", where "hostname" is the IP address or DNS name of your syslog server.
At the command prompt or through the services GUI, start the "Eventlog to Syslog" service.
The service is now running and forwarding all Eventlog entries via UDP port 514 to the hostname you specified.  Obviously, since this is UDP there will be no error messages if the remote syslog server is down.  
You can also specify custom facilities for Eventlog to Syslog, but I won’t go into them here.  Visit the project homepage.

<br />

**DEPLOYMENT SCRIPT**
Whether you have dozens or hundreds of Windows servers to monitor, a scripted deployment is the easiest and fastest way to go.  If you have thousands of servers to monitor, you should be taking your time with this and plan thoroughly.

Basically, I have a script that I use for installing the service and starting it remotely.  I like to use a tool called "Hyena" to schedule the execution of the script on multiple servers as AT jobs.  A similar tool is "Dameware".  If you're really clever, you can use WMI scripting or even domain logon scripts.  
Whatever method you choose for scheduling and executing the script, the code remains the same.

Prerequisites:  You will need to have the “Eventlog to Syslog” executable, DLL, and deployment script all in one file share on your network for this script to work properly.  Edit the script and change all paths containing the word “fileserver” to suit your needs.  Obviously, this should be the path to the aforementioned network file share.

I should mention that I had initially tried using another free utility called “Winlogd”, which can be found here: http://edoceo.com/creo/winlogd.  This utility works okay, but it had some shortcomings.  It required .Net, and it would not run on 64-bit systems.  It also had some issues on some of my Windows 2003 R2 SP2 systems as well.  The biggest problem was that it did not report uptime events from Windows 2003 servers correctly at all.  This completely hosed my logs.

So, just in case anyone reading this has tried Winlogd as well, I have included an uninstaller routine in my batch file.  It won’t hurt anything to leave it in, but if you really want it gone, just remove the WLDCHECK, WLDREPORT, and WLDREMOVE sections from the batch file.

To summarize the script, it checks to see if “Eventlog to Syslog” already exists on the remote system.  If so, it reports this in a log and quits.  If not, it checks to see if “Winlogd” is on the remote system.  If “Winlogd” is found, it removes it, logs it, and then installs “Eventlog to Syslog”.  Finally, it starts the “Eventlog to Syslog” service and logs it.  By the way, I should also mention that this script will handle terminal servers with no issue.  It is set to change the user mode to “/Install” where appropriate and then set it back to “/Execute” when finished.

So, without further delay, here is my “install.bat” script:

{% highlight bash %}
:: Check to see whether we need to continue
    IF EXIST %systemroot%\system32\evtsys.exe (GOTO :EVTREPORT) ELSE GOTO :WLDCHECK

:EVTREPORT
    echo "Evtsys is already installed on %computername%" >> \\fileserver\syslogd$\report.txt
    GOTO :END

:WLDCHECK
    IF EXIST %systemroot%\system32\winlogd.exe (GOTO :WLDREPORT) ELSE GOTO :DOIT

:WLDREPORT
    echo "Winlogd is installed on %computername%" >> \\fileserver\syslogd$\report.txt
    GOTO :WLDREMOVE

:WLDREMOVE
    change user /install

    c:

    net stop winlogd
    %systemroot%\system32\winlogd -u
    del %systemroot%\system32\winlogd.exe /Q
    change user /execute

    GOTO :DOIT

:DOIT
    change user /install
    copy \\fileserver\syslogd$\32-bit\evtsys.* %systemroot%\system32
    c:
    %systemroot%\system32\evtsys -i -h 10.221.2.24
    net start "Eventlog to Syslog"
    change user /execute
    echo "Successfully installed on %computername%" >> \\fileserver\syslogd$\report.txt

:END
{% endhighlight %}

<br />

**SYSLOG SERVER**

You can likely use any syslog-like system that accepts standard syslog-formatted messages from UDP port 514 in conjunction with the “Eventlog to Syslog” utility.  I prefer to use syslog-ng on a Linux box because it’s free, stable, and easy to configure.  So, obviously my documentation here will only cover syslog-ng on a Linux system.

I chose to use a Fedora system for this deployment initially, because is easily deployed, free, and there is lots of community support.  So, it was a great candidate for testing this.  Of course, my *ahem* test system did eventually become my production syslog server.  I have recently rebuilt this system on an Opensolaris 10 platform.  I will post those handy-dandy directions later.

Here are the steps I took to configure syslog-ng on my Fedora Core 6 system:

As ‘root’, run:
{% highlight bash %}
yum install syslog-ng
{% endhighlight %}

Accept any dependencies, and voila!  Syslog-ng is installed.  Now to configure it…

Syslog and syslog-ng can place log entries in various logfiles, depending on what rules you have set up.  I prefer to have everything dumped to one big log file that is rotated daily.  Once I have a week’s worth of logs, I tarball them, bzip2 them, and throw them up on a fileserver for backup to tape.  This is important for PCI compliance, for all you retailers out there, by the way. 
 
Here is my syslog-ng.conf file:
{% highlight bash %}
# Syslog-ng configuration file. 
###############################################################
# First, set some global options.
###############################################################
options {
        keep_hostname(yes);
        long_hostnames(off);
        sync(1);
        log_fifo_size(2048);
};

###############################################################
# Set up our log sources (local events and everything from port 514)
###############################################################
source src {
        pipe("/proc/kmsg");
        unix-stream("/dev/log");
        internal();
};

source network {
  udp( port(514));
  };

###############################################################
# After that set destinations.  (..Everything to one file per day.)
###############################################################
destination std {
        file("/var/log/hosts/current/$YEAR-$MONTH-$DAY"
                owner(root) group(root) perm(0600) dir_perm(0700) create_dirs(yes)
        );
};

################################################################
# Set up logging to flat files.  (This actually writes the data to files.)
###############################################################
log {
        source(network);
        destination(std);
};

log {
        source(src);
        destination(std);
};
{% endhighlight %}

After a week of running the syslog server, if I check the contents of the log directory (/var/log/hosts/current), I see the following:

{% highlight bash %}
# ls -alh
total 463M
drwxrwxrwx 2 syslog syslog  12K Aug  4 00:00 .
drwxrwxrwx 5 syslog syslog 4.0K Jul 18  2007 ..
-rw------- 1 root root 245M Jul 27 23:59 2008-07-27
-rw------- 1 root root 633M Jul 28 23:59 2008-07-28
-rw------- 1 root root 640M Jul 30 00:00 2008-07-29
-rw------- 1 root root 613M Jul 31 00:00 2008-07-30
-rw------- 1 root root 610M Jul 31 23:59 2008-07-31
-rw------- 1 root root 515M Aug  1 23:59 2008-08-01
-rw------- 1 root root 232M Aug  2 23:59 2008-08-02
{% endhighlight %}

You see seven files; each is named with the year-month-day on which it was created.  This ensures that no two log files are ever named the same, and it makes historical research very easy.  I want to take a moment to point out the size of these files.  Notice that each one of the weekday files is over 600MB.  I have less than 200 servers reporting to this syslog server.  You can imagine if I had upwards of 500 servers.  This is why I mentioned earlier that if you have 1000 or more servers, you need to really take your time and plan this deployment.  Tossing that much data around your network tends to have a noticeable effect on performance.  

Now, being that these files are 100% plain-old text, they compress very nicely.  Here is the log rotation script I use with cron:

{% highlight bash %}
#!/bin/sh
#################################
###  "syslog_archiver" Written by Malachi McCabe
###  The purpose of this script is to move the syslog
###  logs to an archive location and compress them.  It
###  then uploads the compressed logs to another server
###  for tape archival to meet PCI requirements.
#################################

#################################
###  Set some variables.
#################################
CTIME=
CTIME=`date +%Y%m%d`
SUBJECT="Syslog Archival Process"
TO=myemailaddress@work.com

#################################
### Compress and move the logs to the archive directory.
#################################
mkdir /tmp/syslog-tmp
mv /var/log/hosts/current/* /tmp/syslog-tmp/
/bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true
/etc/init.d/swatch stop
tar -cvjf /var/log/hosts/archive/syslog-$CTIME.bz2 /tmp/syslog-tmp/*
rm -rf /tmp/syslog-tmp
/etc/init.d/swatch start

#################################
### Upload the archive to the remote server for tape backup.
#################################
cd /var/log/hosts/archive
smbclient \\\\YOURFILESERVER\\syslog$ YOURPASSWORD -U syslogd -W YOURDOMAIN -c "prompt off;put syslog-$CTIME.bz2;exit"

#################################
### Notify us that the syslog archive process has run.
#################################
mailx -s "${SUBJECT}" ${TO} <<-EOF
This week's syslog archive "syslog-$CTIME.bz2" has been uploaded successfully for tape backup.
EOF
{% endhighlight %}

I do want to point out that I am uploading my compressed log file archives to a Windows server.  For interoperability, I used Samba and a domain service account.  In a nutshell, this script will move your current log files to a temporary location, restart syslog, compress the log files, upload them to a Windows file server, and finally email you that the process has completed.

My system runs this script every Sunday at midnight, but you can set yours to whatever you like.

<br />

**SWATCH CONFIGURATION**

So, you have a few Windows servers sending their event log entries to a syslog server now, eh?  Great!  Now you can search through it using grep, awk, etc to find whatever your looking for.  Why not take it a step further, though?  Why be reactive instead of proactive?  Why not use swatch to monitor your new syslog server for specific Windows events?  Here’s how:

First, install swatch as ‘root’:
{% highlight bash %}
# yum install swatch
{% endhighlight %}

Now, let’s configure it.  Here’s my swatch configuration script:

{% highlight bash %}
######################################################
### Configuration file for Swatch
######################################################
# Ignore the nextorclean service
ignore          /nextorclean/
ignore          /domain: HIS/
ignore          /domain: ASPECTCC/

# Kernel problems or system reboots
#watchfor        /panic|halt/
#                echo bold
#                mail myemailaddress@work.com,subject=System Reboot

# Logon attempted with disabled account
watchfor        /Account currently disabled/
                mail myemailaddress@work.com,subject=Logon Attempted With Disabled Account
                threshold track_by=$4:$17,type=limit,count=1,seconds=20

# Logon attempted with account locked out
watchfor        /Account locked out/
                mail myemailaddress@work.com,subject=Five Logon Attempts with Locked Out Account
                threshold track_by=$4:$17,type=both,count=5,seconds=20

# Unknown user name or bad password
watchfor        /Unknown user name or bad password/
                mail myemailaddress@work.com,subject=Five Attempts With Unknown Username Or Bad Password
                threshold track_by=$4:$20,type=both,count=5,seconds=20

# SQL service monitoring
watchfor        /MSSQLSERVER service/
                mail myemailaddress@work.com,subject=SQL Service State Changed

# Manual server reboots
watchfor        /initiated the restart/
                mail myemailaddress@work.com,subject=Forcible Server Reboot

# Citrix Data Store connectivity
#watchfor        /IMA_RESULT_DBCONNECT_FAILURE/
#                mail myemailaddress@work.com,subject=Unable to Contact CTX Data Store

# Nextor Service Monitoring (Enterprise Store Server)
watchfor       /nnrtl001.+nextor.+service entered the stopped state/
               mail myemailaddress@work.com,subject=Nextor Service Stoppage On Enterprise Server

# Nextor Service Monitoring (KoP Store Server)
watchfor       /retserv1.+nextor.+service entered the stopped state/
               mail myemailaddress@work.com,subject=Nextor Service Stoppage On Retail Server

# This alerts on failed su attempts. This can get annoying if you have a lot
# of boxes and users.
watchfor       /\'su root\' failed/
               echo bold
               mail myemailaddress@work.com,subject=Failed SU To Root

# Full filesystems on Sun Boxes
watchfor       /file system full/
               mail myemailaddress@work.com,subject=File System Full

# Dell Power Supply Issues
watchfor        /Voltage sensor detected a failure/
                mail myemailaddress@work.com,subject=Dell Server Power Supply Issue
                threshold track_by=$4:$8,type=limit,count=1,seconds=60

#System error while enumerating the domain controllers
# Windows Domain Visibility Issues
watchfor        /System error while enumerating the domain controllers/
                mail myemailaddress@work.com,subject=Unable To Enumerate Domain Controllers

# NetBackup Client Service Stoppage
#watchfor        /NetBackup Client Service is shutting down/
#                mail myemailaddress@work.com,subject=NetBackup Client Service Stoppage

# Sun Server Kernel Panic
watchfor       /reboot after panic/
               mail myemailaddress@work.com,subject=Sun Server Crash - Contact Tech Svcs. On Call Immediately

# Sun Server Storage Failure
watchfor        /The number of IO errors associated with a ZFS device exceeded/
                mail myemailaddress@work.com,subject=Sun Server Disk Failure - Contact Tech Svcs. On Call Immediately


# Sun Server Multiple Logon Failure
watchfor        /REPEATED LOGIN FAILURES ON/
                mail myemailaddress@work.com,subject=Sun Server - Multiple Logon Failures

# Sun Server SCSI Bus Reset
watchfor        /got external SCSI bus reset/
                mail myemailaddress@work.com,subject=Sun Server - SCSI Bus Reset

# Sun Server SCSI Device Failure
watchfor        /Command failed to complete...Device is gone/
                mail myemailaddress@work.com,subject=Sun Server - SCSI Device Failure
{% endhighlight %}

I absolutely love swatch.  As you can see, I only have a few things that it is watching for, but it’s such a nice change to be alerted the second there’s an issue.  Since I carry a Blackberry, I get the notifications no matter where I’m at.  I suggest you read up on swatch, as there are several alert methods you can use.  You can have it send emails, SMS messages to cell phones, tie it to qpage for alphanumeric pager alerts, etc.  You can also have it pop messages up on the screen.  

Swatch uses Perl regular expressions to parse the log entries, so it’s very easy to configure new alert watches.  Imagine being alerted when specific services are restarted, servers are rebooted, users login, etc.  You can report on absolutely anything that is sent to syslog.  I have turned up the logging level in our domain so that I can capture all kinds of Windows logon and security events as well.   You may or may not choose to do the same.  Be warned that doing this nearly doubled the amount of syslog data that I capture on a daily basis.

Finally, here is the script I use to restart swatch.  I had issues with the original init script getting swatch to restart cleanly, so I wrote my own.

{% highlight bash %}
# !/bin/sh
#
# This shell script takes care of starting and stopping swatch.
# processname: swatch

 RETVAL=0
 test -x /usr/bin/swatch || exit 0
 start(){
   echo "Starting swatch"
     # Spawn a new swatch program
       /usr/bin/swatch -c /etc/swatchrc --tail-file=/var/log/hosts/current/* &
       echo $PID
 return $RETVAL
}
stop () {
     # stop daemon
   echo "Stopping swatch:" $PROG
#   killall swatch
   for i in `ps aux |grep swatch |grep -v "grep" |gawk '{print $2}'`; do kill -9 ${i}; done
   return $RETVAL
}
restart () {
   stop
   start
   RETVAL=$?
   return $RETVAL
}

case "$1" in
   start)
       start
       ;;
   stop)
       stop
       ;;
   restart)
       restart
       ;;
   *)
       echo "Usage: $0 {start|stop|restart}"
       RETVAL=1
esac
exit $RETVAL
{% endhighlight %}

**SYNOPSIS**
And that’s it!  All in all, this is a pretty simple thing to get going in any environment.  You may choose to customize it further, or scale it down from what I have provided.  Whatever you decide, I hope that this tutorial was helpful to you.