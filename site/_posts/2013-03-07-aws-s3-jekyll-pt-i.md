---
title: Amazon S3 + Jekyll = Infinitely Scaling Blog (And Cheap Too) - PART I
date: 2013-03-07 23:20
---

For some of us bloggers, one visitor a month is a big deal. We're like lonely little islands in the vast ocean of the Internet.  As I'm writing this, even prior to this post, my entire website is precisely 58,271 bytes. 

Clearly I don't need much in the way of resources and a home PC could host my site nicely. Even that's overkill though, and it's going to cost me if I leave it up 24 hours a day.  And of course I would, because with only 1 visitor a month, I don't want to miss them just because I'm pinching pennies.

[Energy.Gov](http://energy.gov/energysaver/articles/estimating-appliance-and-home-electronic-energy-use) says running that PC will cost me about $260 a year, or $21.66 a month.  And really, the PC is way too powerful for my one lonely visitor each month.  But what if traffic picks up for some reason? I could be flooded with traffic, the site will crash, and my would-be visitors will all leave, never to return.

Enter [Amazon AWS](http://aws.amazon.com/).  I can easily fire up a [t1.micro](http://aws.amazon.com/ec2/instance-types/) EC2 instance for a paltry $14.64 per month, and I even get it preloaded with Wordpress for no extra charge. It's a few extra bucks a month compared to the trusty old PC, but now it's running on one of the most robust, fault-tolerant computing infrastructures on the planet.

That's all well-and good, but what about scalability?  Sure, I can bring all the powers of AWS to bear and turn the lone Wordpress instance into an all powerful auto-scaling monster, but seriously... I already have a day job.  I needed something simple and cheap, while still allowing me my delusions of grandeur by providing that scalability that I like to pretend I'll need someday.

Now, enter S3. [Amazon's Simple Storage Service](http://aws.amazon.com/s3/) is amazingly redundant, boasting *eleven* nines of durability. It sounds silly even saying it. It's not only durable, it's cheap and can even host a web site. The minimum billing unit is 1GB on S3 which will run me $0.10 per month.  The first 1GB of outbound traffic is free, which means I can serve well over 10,000 visits in a month.

Unfortunately, I can't run Wordpress on S3.  Enter [Jekyll](http://jekyllrb.com/).

Jekyll is a very simple static website generator designed specifically for bloggers.  Jekyll can take your web page content and convert it into CSS backed HTML that can then be hosted from S3.  

So S3 is where my site lives for next to nothing and Jekyll helps me get it there.  But where does Jekyll live?  Like Wordpress, it needs an operating system to function.

Remember that t1.micro I mentioned earlier?  That instance is billed at the price of $0.02 per hour.  Yes, two cents.  Since I'm not hosting the webpage itself on the instance, I only need it long enough for Jekyll to generate my site and upload it to S3. After that, I simply terminate it.

Of course that means I have to rebuild the instance, install all the software and copy all of my site data to it every time I want to post on my blog.  Sounds awful, right?  It's not and here's why.  You can script your instances to that they auto-configure themselves while they are booting for the first time.

Basically, here's what happens when I post.  I write my post and upload it to [GitHub](https://github.com/) (free). Then I spin up a t1.micro instance using a boot script I put together.  The script installs everything on it's own and then downloads the entire site along with the new post from GitHub.  The script fires up Jekyll and then uploads it all to S3.  Finally I terminate the instance and I'm done.  The whole process only took about two minutes. You can actually automate the entire thing with a scheduled task. Upload to GitHub and walk away.

So, now I have worry-free uptime, infinite scalability, and oh by the way it's costing $8.53 per *YEAR* if I blog every day (yeah right).  Add [Google Analytics](http://www.google.com/analytics/) (free), and [Disqus](http://www.disqus.com/) (also free) for comments, and we've got the makings of a blog with some street cred. Did I mention that this setup is [free for a year](http://aws.amazon.com/free/) to new AWS customers?

In my next post, I'll outline all the steps you need to essentially clone my site.



