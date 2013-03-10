---
layout: post
title: Amazon S3 + Jekyll = Infinitely Scaling Blog - Part II
date: 2013-03-10 16:23
---
In my last post, I promised to give instructions on how to clone my setup.  I'll be straight with you here, there are a lot of steps and components to get this set up. It's not difficult, but there are a few ingredients and various accounts that you're going to need.

I won't be covering CloudFront, Route53, Disqus, or Google Analytics in this post.  The intent here is just to get a simple blog up and running using EC2, S3, Jekyll and Github.  You can add these other features once we have the basic setup done and working.

Before we can get started, you're going to need an [*Amazon AWS*](http://aws.amazon.com/) account and a [*GitHub*](https://github.com/) account.  Once you have those, we can continue.

**Overview of Steps**
1. Install the GitHub client on the computer you plan to blog from
2. Fork and clone my repo
3. Gather AWS account info
4. Create and configure an S3 bucket
5. Copy and personalize the bootstrap script
6. Launch an instance using the script
7. Confirm the site works

**GitHub**
GitHub is essentially is an Internet-based source code repository that supports version control.  GitHub has some really great features for us bloggers; version control, project forking for development, and a centralized location to store your site data.  In fact, a lot of people blog directly on GitHub itself.  You can certainly go this route if you prefer. I was looking for something a bit more involved that could provide a segue into what Amazon AWS can do.

After creating your GitHub account, fork [my repository](https://github.com/Tacplan/blogsample) by simple clicking the "*Fork*" button, and then install the [GitHub client](http://github-windows.s3.amazonaws.com/GitHubSetup.exe) on your PC.  I'm working with Windows, so my directions will be centered on that.  There are GitHub clients for Mac and Linux as well, but you'll have to find directions for those on your own.

Launch the GitHub client you just installed and log in to your newly created account.  You should now see any repositories you have created (if you went through the new account intro), as well as the forked copy of my sample blog.  Click on the sample blog and select "*Clone*".  This will download an exact copy to "*%userprofile%\documents\github\sampleblog*".

You may want to create a shortcut to this directory and place it on your desktop, as this is where you'll be working on making the blog your own.


**Amazon AWS Account**
If you haven't done so already, you're going to need to generate and document your "*AWS Access Key ID*" and "*AWS Secret Key*" from the [AWS Security Credentials Portal](https://portal.aws.amazon.com/gp/aws/securityCredentials). Eric Hammond, over at [Alestic.com](http://alestic.com), has a great [write-up](http://alestic.com/2009/11/ec2-credentials) on the different types of AWS credentials. I highly recommend his site, as he's got a ton of fantastic info on AWS.  My bootstrap script actually borrows from his [autoscaling script](http://alestic.com/2011/11/ec2-schedule-instance).

**S3 Bucket Config**
Now you need to create an S3 bucket with the same name as your blog domain name. For example, if your blog will eventually live at "*http://myawesomeblog.com*", then name the bucket "*myawesomeblog.com*". It's not a bit deal if you don't have your own domain name yet- you can still host your blog on S3. Also, since a copy of your blog will be stored in three places (GitHub, S3, and your PC), you can opt for "*Reduced Redundancy Storage*" on S3 to save you a few pennies.

Amazon has a great write-up on how to set up the S3 bucket [here](http://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html).

Make sure and note the "*Endpoint*" of your S3 bucket.  You can see this by going to the properties page of the bucket and selecting "*Static Website Hosting*".  You'll need this to see your blog once everything is uploaded.

**Bootstrap Script**
Download my bootstrap script [here](http://www.tacplan.com/bootstrap_ec2), and save it to your machine as "*bootstrap_ec2*".  You'll need to set a few variables to match your specific information, so ahead and open this with a text editor.  I highly recommend [Sublime Text](http://www.sublimetext.com/) or [Notepad++](http://notepad-plus-plus.org/). But you could just as easily use plain old MS Notepad. 

- *AWS Access key ID*
- *AWS Access Key Secret*
- *S3 Bucket Name*
- *URL to your GitHub fork of my repo*

Below is an excerpt of the sections you need to modify:
` # Copy and paste your AWS keys: `
` export AWS_ACCESS_KEY_ID=AKISH82DKFH2811D490G `
` export AWS_ACCESS_KEY_SECRET=dn/84alkDLms73KSNDl+fCsID38+uh81Z `

` # Set the name of your S3 bucket: `
` export S3_BUCKET=www.myawesomeblog.com `

` # Set the URL to your GitHub fork: `
` export GITPATH=git://github.com/youraccountname/blogsample.git `

` # Set your email address to be alerted when this instance is done `
` export EMAIL=yourname@youremaildomain.com `
 
**The Blogging Process**
Now you should have all the necessary pieces in place. Here's how the blogging process will work. You don't need to write a post now, I just wanted to explain how the process works. Feel free to move on to the next section and come back here when you want to write a test post.
Jekyll uses a very simple markup language called [*Markdown*](http://en.wikipedia.org/wiki/Markdown) to format your blog posts.  Don't panic, it's really easy and there are a number of various Markdown editors if you don't want to use a plain text editor.  One free editor I like is called [Markdownpad](http://www.markdownpad.com).
When you write a new post, save it with a "year-month-day-name.md" format to "%userprofile%\documents\github\blogsample\site\_posts", like this: *2013-03-07-my-first-post.md*
Next, open up your GitHub client and hit "*Refresh*" at the top.  It will recognize that you have made a change to your local cloned copy of the repo.  A yellow box in the upper-right will ask you for a "*Commit Message*".  Just enter "*Test Post*" if you like and click "*Commit*".

Now your new post is ready to be uploaded to the the forked GitHub repo on the Internet.  Click "*Sync*" at the top.

Finally, you'll fire up and EC2 instance which will download everything from GitHub, convert it using Jekyll, upload it to S3, email you when it's done, and finally terminate itself.


**Launching the EC2 Instance**

You'll launch an EC2 instance only when you're ready to upload changes or posts to your site.  Let's go ahead and give this a try.

Log into [AWS](http://aws.amazon.com) and go to "*Services*", then "*EC2*".
- Click "*Launch Instance*"
- Click "*Continue*"
- On the "*Quick Start*" tab, select "**Ubuntu Server 12.10**"
- Make sure "*t1.micro*" is selected for "*Instance Type*" and click "*Continue*"
- In the "*User Data*" section, select "*as file*"
- Click "*Choose file*" and browse to the bootstrap_ec2 file you edited earlier.
- Set "*Shutdown Behavior*" to "*Terminate*"
- Click "*Continue*", then "*Continue*" again
- You can either choose your existing keypair at this point, or just select "*Proceed without keypair*" and click "*Continue*".
- Select "*Choose one or more of your existing Security Groups*" and make sure the default group is selected.
- Click "*Continue*" and the "*Launch*".
- Click "*Close*"
- After several minutes, you should receive an email telling you that your site has been loaded, along with some other somewhat useful information.
 
**Testing**
To confirm everything works as expected, simply go to the URL of your bucket that you wrote down earlier: http://*your_bucket_name*..s3-website-us-east-1.amazonaws.com