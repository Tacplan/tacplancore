---
layout: post
title: Amazon S3 + Jekyll = Infinitely Scaling Blog - Part I
date: 2013-03-07 23:23
tags:
- jekyll
- aws
- s3
- blogging
- ec2
- github
---

For many of us bloggers, one visitor a month is a big deal. We're like lonely little islands in the vast ocean of the Internet.  As I'm writing this, even prior to this post, my entire website is precisely 58,271 bytes. 

Clearly I don't need much in the way of resources and a home PC could host my site nicely. Even that's overkill though, and it's going to cost me if I leave it up 24 hours a day.  And of course I would, because with only 1 visitor a month, I don't want to miss them just because I'm pinching pennies.

[Energy.Gov](http://energy.gov/energysaver/articles/estimating-appliance-and-home-electronic-energy-use) says running that PC will cost me about $260 a year, or $21.66 a month.  And really, the PC is way too powerful for my one lonely visitor each month.  But what if traffic picks up for some reason? I could be flooded with traffic, the site will crash, and my would-be visitors will all leave, never to return.

Enter [Amazon AWS](http://aws.amazon.com/).  I can easily fire up a [t1.micro](http://aws.amazon.com/ec2/instance-types/) EC2 instance for a paltry $14.64 per month, and I even get it preloaded with Wordpress for no extra charge. It's a bit cheaper than the trusty old PC, and now it's running on one of the most robust, fault-tolerant computing infrastructures on the planet.

That's all well-and good, but what about scalability?  Sure, I can bring all the powers of AWS to bear and turn the lone Wordpress instance into an all powerful auto-scaling monster, but seriously... I already have a day job.  I needed something simple and cheap, while still allowing me my delusions of grandeur by providing that scalability that I like to pretend I'll need someday.

Now, enter S3. [Amazon's Simple Storage Service](http://aws.amazon.com/s3/) is amazingly redundant, boasting *eleven* nines of durability. It sounds silly even saying it. It's not only durable, it's cheap and can even host a web site. The minimum billing unit is 1GB on S3 which will run me $0.10 per month.  The first 1GB of outbound traffic is free, which means I can serve well over 10,000 visits in a month.

Unfortunately, I can't run Wordpress on S3.  Enter [Jekyll](http://jekyllrb.com/).

Jekyll is a very simple static website generator designed specifically for bloggers.  Jekyll can take your web page content and convert it into CSS backed HTML that can then be hosted from S3.  

So S3 is where my site lives for next to nothing and Jekyll helps me get it there.  But where does Jekyll live?  Like Wordpress, it needs an operating system to function.

Remember that t1.micro I mentioned earlier?  That instance is billed at the price of $0.02 per hour.  Yes, two cents.  Since I'm not hosting the webpage itself on the instance, I only need it long enough for Jekyll to generate my site and upload it to S3. After that, I simply terminate it.

Of course that means I have to rebuild the instance, install all the software and copy all of my site data to it every time I want to post on my blog.  Sounds awful, right?  It's not and here's why.  You can *script* your instances so that they auto-configure themselves while they are booting for the first time.

Basically, here's what happens when I post.  I write my post and upload it to [GitHub](https://github.com/) (free). Then I spin up a t1.micro instance using a boot script I put together.  The script installs everything on it's own and then downloads the entire site along with the new post from GitHub.  The script fires up Jekyll and then uploads it all to S3.  Finally I terminate the instance and I'm done.  The whole process only takes about two minutes. You can actually automate the entire thing with a scheduled task. Simply upload your post to GitHub and walk away. You could let the scheduled task upload your posts on a nightly basis. 

Two additional services worth mentioning are Amazon Cloudfront to front-end my site so it loads super fast no matter where in the world my readers are, and Amazon Route53 for DNS.  Now I have worry-free uptime, infinite scalability, and oh by the way it costs [$1.00 per month](http://calculator.s3.amazonaws.com/calc5.html#r=IAD&key=calc-5AC5887F-FC67-4777-AE90-60A7623D1844) if I post 3 times a week.

Add [Google Analytics](http://www.google.com/analytics/) (free), [Disqus](http://www.disqus.com/) for comments (also free), and we've got the makings of a blog with some street cred. 

Granted, this setup is more complicated that just signing up for a [Blogger](http://www.blogger.com) account.  My intent here though is to help give a small taste of what is possible with Amazon Web Services.

In my next post, I'll show you what you need to run your own Jekyll blog on S3.