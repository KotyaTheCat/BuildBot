# KotyaTheCat scripts for build Android 10

## What does it do?
Build Android with a single command and send the results to Telegram. Also upload to dropbox your rom

### Installation
1.Go to the sources directory
```bash
#Enter "cd your_source_directory" Ex. if If your directory is named "PE", then enter
cd pe
```
2.Cloning repo
```bash
git clone https://github.com/KotyaTheCat/BuildBot.git bot
```

3.Open bot.conf and configure for yourself

4.Open bot.sh and configure for yourself

### Install DropBox
```bash
cd
wget https://raw.github.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh
chmod +x dropbox_uploader.sh
./dropbox_uploader.sh
```

Go to your browser at https://www2.dropbox.com/developers/apps and create a new Dropbox app. Enter the required information in command line. After creating a new application, on the next page you will see the "Generate token" button. Generate it and type in the command line.
This completes the setup of the Dropbox Uploader. To verify authentication success, run the following command:
```bash
./dropbox_uploader.sh info
```

Done!

### How to use
1.Go to the sources directory
```bash
#Enter "cd your_source_directory" Ex. if your directory is named "PE", then enter
cd pe

```

2.Enter 
```bash
. bot/bot.sh
```

### Thanks:
Based on: https://github.com/SwapnilSoni1999/buildbot_script

Behind Telegram script: https://github.com/fabianonline/telegram.sh

Dropbox installation instructions are taken from here: http://rus-linux.net/MyLDP/internet/dropbox-from-consol.html

---------
Sorry for my bad english :-)
