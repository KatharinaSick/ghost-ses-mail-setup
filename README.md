# Script to send mails about new posts on a Ghost blog via Amazon SES
This repository contains all files and scripts I am using to inform the subscribers of my Ghost blog about new post via email with Amazon SES. Ghost supports only Mailgun for this, so there is a lot of overhead necessary to achieve this goal. That's why it only works semi-automated, which means I always have to trigger the script when creating a new post. 

Additional information about how all of this is working and the reasons why I implemented it can be found [on my blog](https://ksick.dev/using-amazon-ses-to-send-mails-from-a-ghost-blog/).
