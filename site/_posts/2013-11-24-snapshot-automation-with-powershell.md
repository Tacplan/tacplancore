---
layout: post
title: Snapshot Automation With PowerShell
date: 2013-11-24 19:26
tags:
- snapshots
- aws
- ebs
- ec2
- backups
- gfs
- sqs
- sns
- powershell
- windows
---
 
Moving your data to the cloud may be helping you eliminate hardware, but it doesn't get you out of the data backup game. You still need to have the ability to recover data to keep your business going, just as you always have.

AWS opens up several possibilities for implementing or augmenting an effective backup strategy. EBS snapshots are so readily available, simple to take advantage of, and cost effective that I would have to question your I.T. street cred if you didn't leverage them in your AWS environment.

I decided to put together a fairly simple, scripted solution that will provide all the backups of your Windows servers you could possibly want as well as some capacity for centralized logging using SNS with SQS. It's up to you how you pull the SQS log messages.

This system will also prune old snapshots automagically.  Daily, Weekly, and Monthly rotations can be implemented simply by duplicating the script and creating multiple scheduled tasks.

<br/>

**Requirements**

In the future, I plan to write up a cross-platform solution, but for now this solution has the following requirements:

- An EC2 instance running Windows 2008, Windows 2008R2, or Windows 2012.
- Powershell 3+
- Amazon .Net SDK 
- An IAM account to run the process
- Amazon SNS (Optional)
- Amazon SQS (Optional)

<br/>

**AWS Environment Prerequisites**

For this tutorial, I'll assume that you want to leverage SNS and SQS.  If not, ignore the bits about them and be sure to remove references to them from the script.

1. Create a new SNS topic.  I called mine "AutoSnap_SNS_Log".
2. I'm not sure if this is a bug or what, but I had to allow "Everybody" access to my SNS topic.
3. Create a new SQS queue.  I called mine "AutoSnap_SQL_Log".
4. Copy the ARN of the SQS queue and subscribe it to the SNS topic.
5. Create an IAM account to use for your snapshots and call it what you like.  I chose "backupsvc".  You will need to document the Access and Secret keys.
6. Give the IAM account permission to work with snapshots: 

{% highlight bash %}
{
  "Statement": [
    {
      "Action": [
                "ec2:CreateSnapshot",
                "ec2:CreateTags",
                "ec2:DeleteSnapshot",
                "ec2:DeleteTags",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeSnapshots",
                "ec2:DescribeTags",
                "ec2:DescribeVolumeAttribute",
                "ec2:DescribeVolumeStatus",
                "ec2:DescribeVolumes"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
{% endhighlight %}
<br/>
7. Give the IAM account permission to work with SNS:

{% highlight bash %}
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1384967283000",
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": [
        "arn:aws:sns:us-east-1:45678123450123:AutoSnap_SNS_Log"
      ]
    }
  ]
}
{% endhighlight %}
<br/>
8. Give the account permission to work with SQS:

{% highlight bash %}
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1384970961000",
      "Effect": "Allow",
      "Action": [
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage"
      ],
      "Resource": [
        "arn:aws:sqs:us-east-1:45678123450123:AutoSnap_SQS_Log"
      ]
    }
  ]
}
{% endhighlight %}
<br/>
9. Now let's set up our deployment directory. Create a directory called "AWS Tools".

<br/>
10. Download the AWS [SDK](http://aws.amazon.com/powershell) for Windows to "AWS Tools", and rename it to *AWSSDK.msi*.

<br/>
11. I like to make deployment easy and repeatable, so I created the following batch file called, "AutoSnap_Setup.bat".  It only needs to be run once on an instance and sets up the environment and installs the AWS SDK for Windows.

<br/>
{% highlight bat %}
:: EC2 API Config

:: We use SETX to set the IAM credentials and default region as environmental variables.
SETX /M AWS_ACCESS_KEY_ID AKIAIID123456789IUQ
SETX /M AWS_DEFAULT_REGION us-east-1
SETX /M AWS_SECRET_ACCESS_KEY aBcDeFgHiJkLmNoPqRstUvwXyZ/AbCdEfGhIJ12aB34

:: Next we open up PowerShell so that it allows scripts to be run.  If you feel this is unsecure, then feel free to change it.
cmd.exe /c powershell.exe -command "& {Set-ExecutionPolicy RemoteSigned}"

:: This next line simply installs the SDK for you. I renamed it to AWSSDK.msi because it's a more friendly name.
cmd.exe /c msiexec.exe /i "c:\AWS Tools\AWSSDK.msi" /qn /l* "c:\AWS Tools\AWSSDK.log"
{% endhighlight %}
<br/>

*Note*: If you already have an IAM account set up in your environmental variables for other purposes, then you'll need to modify a few things and start using stored credentials- which is a topic that is out of scope here.  Don't worry though, it's easy to implement, and the directions are [here](http://docs.aws.amazon.com/powershell/latest/userguide/specifying-your-aws-credentials.html).
<br/>
12. In a moment we'll create a PowerShell script (.ps1) in the same "AWS Tools" directory, *BUT FIRST* some things to customize:
<br/>

- You can change the time/date stamp format.  Your needs may require the time and not just the date, for example.  The current setting will produce the following stamp for June 1st, 2013:  *060113*

- Set your "Job Group Code".  This is a prefix you can use to designate whether this a daily, monthly, weekly, or whatever type of snapshot.  It's currently set to "STD" for "standard".

- With the above two settings, and the hostname of your EC2 instance, your snapshot's "prefix" will be determined.  The defaults will create this as a snapshot description:  **HOSTNAME_AutoSnap_STD_060113**

This is important, because the delete portion of the script will ONLY DELETE snapshots with that prefix.  This way, you 
don't have to worry about accidentally deleting snapshosts for other instances, or even one-off snapshots that you may have created manually.

It ALSO opens the door for different types of rotations.  For example, you can have four scripts on the same server with different prefixes and expirations as follows:

HOSTNAME_AutoSnap_DAILY_060113, set to expire after 7 days

HOSTNAME_AutoSnap_WEEKLY_060113, set to expire after 14 days

HOSTNAME_AutoSnap_MONTHLY_060113, set to expire after 365 days

HOSTNAME_AutoSnap_YEARLY_060113, never expires

You will be able to use Windows Task Scheduler to configure different execution timings for each script. For now, we will just start with one script called, "AutoSnap.ps1", with the following contents:

{% highlight powershell %}
#***********************
#*** AutoSnap Script ***
#***********************

#*************************
#*** Import AWS Module ***
#*************************

import-module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"

#*********************
#*** Set AWS Creds ***
#*********************

Initialize-AWSDefaults -AccessKey $env:AWS_ACCESS_KEY_ID -SecretKey $env:AWS_SECRET_ACCESS_KEY -Region $env:AWS_DEFAULT_REGION

#*****************
#*** Variables ***
#*****************

# Get Hostname (Leave this as is):
$hName = hostname

# Get Date (Feel free to modify the format (MMddyy, MMddyyyy, etc.):
$dateStamp = Get-Date -format MMddyy

# Define a job group code (STD, DAILY, WEEKLY, TACO, ETC.)
$jobGroup = "STD"

# Description field for snapshots (Leave this as is):
$snapDesc = $hname,"_AutoSnap_",$jobGroup,"_",$dateStamp -join ""

# Set to "$false"; ONLY if you are ready to run in production (I know it sounds backwards):
$viewOnly = $true;

# ARN of the SNS Topic you wish to log to (Set this to your SNS ARN):
$SNSarn = "arn:aws:sns:us-east-1:439241859219:AutoSnap_SNS_Log"

# Max age of oldest snapshot in days (The "Delete Snaps" section will remove snaps older than this.):
$daysBack = 7


#********************
#*** Delete Snaps ***
#********************

Function DelSnap ($x)
{

# Process the snapshots:
foreach ($vi in $volumes)
  { 
     $volumeId = $x

$filter = New-Object Amazon.EC2.Model.Filter
    $filter.Name = "volume-id"
    $filter.Value.Add($volumeId)

    $snapshots = @(get-EC2Snapshot -Filter $filter)
#    Write-Output("`nFor volume-id = " + $volumeId)

foreach ($s in $snapshots)
{
$descCriteria = $false
$dateCriteria = $false
if (!$s.Description)
    {
        continue
    }

else
    {

    if ($s.description.StartsWith($hname + "_AutoSnap_" + $jobGroup))
        {
            $descCriteria = $true
        }

    $d = ([DateTime]::Now).AddDays(-$daysBack)
    if ([DateTime]::Compare($d, $s.StartTime) -gt 0)
        {
            $dateCriteria = $true
        }

    if (!$ViewOnly -AND $descCriteria -AND $dateCriteria )
        {
            $resp = Remove-EC2Snapshot -SnapshotId $s.SnapshotId -Force
            $sdMsg = $s.SnapshotId + "," + $s.StartTime + ",Deleted"
            Publish-SNSMessage -TopicArn $SNSarn -Subject $hname -Message $sdMsg
        }
   }
  }
 }
}

#********************
#*** Create Snaps ***
#********************

# Retrieve InstanceID from the EC2 metadata (PS 3.0 Method)
$myInstanceID = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/instance-id

# Identify volumes attached to this instance
$volumes = (Get-EC2Volume).Attachment | where {$_.InstanceId -eq $myInstanceID } | Select VolumeId

# Iterate through these volumes and snapshot each of them
foreach ($volume in $volumes)
{
    New-EC2Snapshot $volume.VolumeId -Description $snapDesc
    $scMsg = "Snapshot " + $snapDesc + " created for volume " + $snapDesc
    Publish-SNSMessage -TopicArn $SNSarn -Subject $hName -Message $scMsg
    DelSnap $volume.VolumeID
}
{% endhighlight %}

<br/>

##Create a snapshot##
You should now have a directory with the following contents:
- AutoSnap.ps1
- AutoSnap_Setup.bat
- AWSSDK.msi

To set up the instance for running the script in the future, right-click on the batch file and run it as Administrator.  You only have to do this once, and it will perform the following steps:

1. Set system environmental variables for your AWS credentials and default region.
2. Allow unsigned scripts to be executed in PowerShell.
3. Install the AWS SDK for Windows.

Once the batch file is finished, you can execute the PowerShell script itself.  The script will identify each attached EBS volume and initiate a snapshot for each.  It will also look for snapshots that match the prefix rules you set that are older than the age you set, then delete them.

For automation, I like to create a scheduled task and then export the config to the "AWS Tools" directory.  Then I can simply copy the directory to each instance I want to set this up on, run the batch file, import the .xml to Task Scheduler, and walk away.  That instance is now set up for backups.

You can get pretty creative with this.  Try putting the "AWS Tools" directory in S3, then creating a User Data script that will auto deploy this on every Windows instance you create.