# ELK-SIEM-Setup
A guide for building your own SIEM using the Elasticsearch, Beats, and Kibana, and how to simulate, analyze and triage attacks for a homelab. Courtesy of the internet and other sources.

# A Very Friendly Warning
Given that this is still being developed, nothing is final. If you are going step-by-step in this guide assuming its <strong>unfinished form</strong> (that is, using this guide before it is totally complete), be warned that you may do either 1) Ruining the final build or 2) Unneeded time wasting steps.

That is all :)

# Preface
<strong>Big</strong> thank you to all of the lovely sources on the internet. I am not one to shy away from reading documentation but this kind of project is virutally impossible for me given my limited knowledge of the ELK stack.

As stated above, there are many sources I consulted, all of which will be linked below for your own reading. The following will be a step-by-step guide of me <strong>creating my own SIEM</strong> using Oracle VirtualBox and namely Elastissearch and Kibana for indexing/analyzing and visualizing our log data respectively.

This guide is aimed to be very step-by-step oriented; I guide you through everything as well as I can. If you do have questions, feel free to message me on Discord (nubbieeee) or email me (sherm5344@gmail.com)! Also massive shoutout to [crin](https://www.youtube.com/@basedtutorials/videos) for getting <strong>me</strong> properly started in cybersec. Without him, I would probably be aimlessly doing programming projects or frying my ESP32.

Lastly, please check out the <strong>[Sources section](#sources)</strong> of this guide for any minor comments and important documentation. If you would like to contribute to this repo, feel free to message me or make a PR to the repo!

# SIEM Features
<strong>Basic features</strong> should include:
- Log ingestion (mainly network-related logs and OS log data for initial testing. Beats can be used for ingest.)
- Log parsing/querying (KQL can easily query for us + Beats for basic parsing.)
- Dashboards (Kibana duh)
- Alerts (Achieved inside the actual SIEM UI)

You may notice that I did not include retention, and that is because I do not plan to retain data for this solution. This is made for a homelab setp; not a production environment where retention is necessary to trash malicious behaviour.

# The Setup Begins
This is our first step into our SIEM-building journey. 

First things first, we will get a VM set up using VirtualBox. Because I am such a nice kiddo, <strong>I have a bash script made to install VirtualBox 7.1 for Ubuntu linked on this repo :)</strong> Sources are linked below specifically for this setup.

Once VirtualBox is set up, we can install an ISO for our VM; preferably Linux. I am running an [Ubuntu Server VM](https://releases.ubuntu.com/bionic/). 

To set up the VM:
1. Open VirtualBox and Select `Machine` then `New`.
2. Give your VM a cool name and select the previously installed ISO image as your chosen OS.
3. Check the box to skip the unattented install. This is so we can tinker everything ourselves.
4. Adjust virtual hardware settings. I have my VM running 4GB of RAM, 2 CPU cores and ~50GB of SSD storage.
5. Start up your VM once everything is ready!

To set up the OS on our VM:
1. Select your language accordingly. ![Select a Language](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/select-language.png)
2. If you get an "installer update" notice, you can skip it as you wish.
3. <strong>Record the IP shown next to DHCPv4, we will need this!</strong>
4. We don't need a proxy, so we can skip configuring one. We also don't need an alternative mirror for Ubuntu.
5. Continue setting up the storage config for the OS, there is no need to tinker with anything unless <strong>you</strong> want to :) ![Storage Conig](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/storage-config.png)
6. Confirm your user credentials and SSH setup. We don't need any featured software on our VM, so continue with the installation. ![Inputting user credentials, you can change yours to your liking!](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/profile-setup.png)
7. Wait for the OS install to complete :) ![](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/waiting-for-install.png)

Congrats! You're one step closer to a lovely homelab setup. Let's continue to our next step of our journey; installing and Configuring Elasticsearch.

# Installing and Configuring Elasticsearch
Once you reboot your system, continue to logging in as your user. When you're in, your screen should look something like this:
![Voila](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/login-complete.png)

The last thing we need to do before getting to real SIEM setup fun is to update our system with the following commands:
```
sudo apt update && sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt install zip unzip -y
sudo apt install jq -y
```
If you're done for the day like me, you can shutdown your VM by going to `Machine` --> `ACPI Shutdown` and return later :) otherwise, run `sudo reboot` to continue.

From here on out, we will be using SSH on our host machine instead of using VirtualBox.

# Intermission: "SSH no worko!"
If you're like me and SOMEHOW don't have ssh enabled by default, you can and should do the following:
1. Run `sudo systemctl status ssh` to see if SSH is even live on your system. 
2. If you see an error entailing `ssh.service` couldn't be found. Don't panic. We will simply reinstall OpenSSH so we can continue.
3. Run the following command: `sudo apt-get remove --purge openssh-server&& sudo apt-get update && sudo apt-get install openssh-server`.
4. If all is well, you can run `sudo systemctl status ssh` and see that SSH is currently a dead process. Run `sudo systemctl start ssh` to start it up! You can also run `sudo systemctl enable ssh` to just have it be a startup process.

Because I am such a nice guy, I have left a script on this repo that can do all of this for you :) 

# Intermission: More SSH Setup
Fun fact, we can't just SSH and magically run on our VM. No, that'd be too easy. We actually have to do <strong>port forwarding</strong> to achieve this. Simply put, we make an SSH request on a certain port, which then gets sent to our VM at port 22; the port for SSH connections.

To achieve this, I created this rule by going to the `Settings` tab in VirtualBox and going to `Network` then `Port Forwarding`. ![Networking Page](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/network-settings.png).

From here, I make the following Port Forwarding rule:
![](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/forwarding-rule.png)
What this basically means is that whenever I send a TCP request to port 2222 on my machine, regardless of the IP used to specify the host, it will be forwarded to port 22 on the Guest IP, which is our DHCP IP address from before. <strong>You can (and should) change the Host IP value to something that isn't blank since that will allow any machine to access the VM effectively. You can specify 127.0.0.1 for the Host IP to only allow localhost/your machine to access the VM.</strong>

Moment of truth, we should be able to `ssh` given any IP address and on port 2222. Run `ssh -p 2222 SERVER_USERNAME@127.0.0.1` and hope for the best!
![This took me like 20-30 minutes.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/ssh-success.png)

Success! We can now continue setting up our VM, or be like me and shutdown everything and chill :)

# Continuing to setup Elasticsearch
<strong>The horrors persist but so do we, let's continue!</strong> If your VM is not running right now, go and start it up. We'll SSH in just like before and get straight to business.

Firstly, we will be installing `apt-transport-https`, which on its own enables APT transport to be done w/ HTTPS and not HTTP; slightly more secure stuff for our VM which could prove useful for production environments.

Run `sudo apt install apt-transport-https -y` and continue. Next we add the GPG key for Elasticsearch and its repo to our ubuntu sources.

Run `wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -` to add the GPG key and `echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list` to see the repo in our ubuntu sources. 
![GPG and repo added!](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/gpg-repo-success.png)

Success! Update our packages then install elasticsearch. Run `sudo apt update -y && sudo apt install elasticsearch -y`.

Now that elasticsearch is installed, we need to reload all running daemons and services on our VM. Since we are adding a new service (Elasticsearch), this is necessary. It wasn't needed for SSH since we changed nothing with configuration files, and configuration is already handled by apt (to my knowledge) but for Elasticsearch, we will be modifying our configuration files.

We will want to confirm that elasticsearch is actually on our system, so run `sudo systemctl status elasticsearch.service`, we preferably want to see a 'dead' process.
![Yes I did a typo.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/elasticsearch-success.png)

Real talk, I included that typo to show that I am human just like you. Creating this guide is both for my learning and so you can get a lovely homelab setup to enjoy cybersec :) With that being said, we are officially finished the installation phase for elasticsearch and will now get to configuring it.

# Configuring Elasticsearch and Running the Cluster
This step is entirely for configuring elasticsearch; telling it how to run, what ports it needs, communication, etc.

Open `/etc/elasticsearch/elasticsearch.yml` in a text editor (neovim da goat). If you are using a terminal editor like me, run `sudo EDITOR_OF_CHOICE ELASTICSEARCH.YML PATH`. Firstly, we will edit the cluster.name property to be the name of your choice for your homelab. 
![Delete those pesky pound symbols.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/edit-elasticsearch-config.png)

Continue editing the file. The `network.host` property will be our VM's IP address. The `http.port` property will be left alone, but make sure to uncomment it, and lastly, add the `discovery.type` property (this property tells Elasticsearch how it should form a cluster). <strong>Do not forget the colon next to the property name!</strong> 

Once we are done, go ahead and close the YML file. Congrats, our config work here is done (temporarily)! We can now go ahead and start the `elasticsearch.service` service, then check the JSON output of Elasticsearch at our IP address + HTTP port--you'll see what I mean :)

Run `sudo systemctl start elasticsearch` and wait a lil for the command to complete. We can also run `sudo systemctl enable elasticsearch` to automatically start the service on boot of our VM, if you wish. Once the command completes, run `curl --get http://NETWORK_HOST_IP:9200`. NETWORK_HOST_IP is the network.host IP we have in our config file!
![We got something!!!](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/elasticsearch-curl-success.png)

Congratulations, we just set up Elasticsearch and can confirm that a cluster is up and running. 9200 is where we will send all of our logged data to; from Beats or Elastic Agents if you go down that route. Our next step is setting up Kibana in the same manner.

If you ever want to edit the `elasticsearch.yml` configuration on your own time, <strong>you will need to run `sudo systemctl restart elasticsearch.service` so that the updated configuarion is read by Elasticsearch.</strong>

# Configuring Kibana
Configuring Kibana starts with installing it; run `sudo apt install kibana -y`.

Next we will update the YML configuration of Kibana just like we did with Elasticsearch. In my case of running Vim as my editor, run `sudo vim /etc/kibana/kibana.yml`.

We will leave the `server.port` property alone as port 5601 is the default option and we have no need to edit it. We will edit the `server.host` and `server.name` properties to be our IP address and an appropriate name respectively. One thing I did notice is that you can adjust the credentials for accessing the Kibana server. You can leave them blank since Elasticsearch will require you to authenticate before touching anything with Kibana, but certainly for production/entreprise environments this is worth changing.
![Our edits.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/kibana-config.png)
![Default credentials are a big nono!](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/kibana-nono-security.png)

Save and exit our changes to the YML file and go ahead and start up the Kibana service. If you're like me and have Elasticsearch not enabled in systemd, you will need to start it up in the following order:
1. Start Elasticsearch w/ `sudo systemctl start elasticsearch` if not already started.
2. <strong>Recall that if you make edits to the Elasticsearch.yml configuration, you must run `sudo systemctl restart elasticsearch` to enable your changes.</strong>
3. Since we have started Elasticsearch and/or updated it, we can go ahead and start Kibana w/ `sudo systemctl start kibana`. We can also make Kibana run on boot w/ `sudo systemctl enable kibana`.

Now, contrary to the very odd guide posted as the "massive installation/setup guide below", we do <strong>not</strong> need to restart Elasticsearch whenever we run Kibana; we only need to restart it when we make changes to its configurations.

Once both Elasticsearch and Kibana are running, we will go ahead and check the status of both services by running `sudo systemctl status elasticsearch && sudo systemctl status kibana`.
![Both services running just fine.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/elastic-kibana-success.png)

That "legacy OpenSSL" message thing is not an issue. According to ChatGPT (yes you heard that right), this is simply for backwards compatibility measures involving communication with Kibana's Node.js runtime. Basically, we do not care in the slightest. 

Kibana and Elasticsearch are now up and running and all that's left is Beats for ingestion. To quickly go over Beats, we will actually be using <strong>filebeat</strong>, which is a kind of Beat offered by Beats (wowza). [Here is a link for further reading on other beats you can use.](https://www.objectrocket.com/resource/what-are-elasticsearch-beats/) For our purposes, filebeat will be just fine to get going and testing our environment. However, I will personally guide you through installing <strong>Winlogbeat</strong> to create our very own mock attack inspired by <strong>chroma</strong> on crin's server; Sally running PowerShell.

If you're closing down like me for the night, you can run `sudo systemctl stop kibana` and `sudo systemctl stop elasticsearch` <strong>in that order</strong> to safely close down our active services :)

# Configuring Filebeat
To be continued...

# Sources
- [Official Elastic Docs on upgrading Elastic components. Highly recommend you consult both this and other sources if you wish to upgrade your lab.](https://www.elastic.co/guide/en/elastic-stack/current/upgrading-elastic-stack.html)
- [Official Elastic Docs on downloading Beats but also for adding the Elastic repo w/ APT or YUM.](https://www.elastic.co/guide/en/beats/filebeat/current/setup-repositories.html)
- A whole lot of ChatGPT and Google Searching. It helps to know the 'why' behind what we're doing especially in cybersecurity!
- [Massive installation and setup guide which I consulted throughout my journey](https://www.leveleffect.com/blog/how-to-set-up-your-own-home-lab-with-elk?utm_source=chatgpt.com)
- [Consult this for VirtualBox downloads. Go straight to the wget command if you're on Ubuntu/Debian-based repos like me, or use my script to install VirtualBox lol](https://www.virtualbox.org/wiki/Linux_Downloads)
- [Consulted for a bug with VirtualBox download; USB enumerate.](https://www.youtube.com/watch?v=7Bdm_-JNiSc&t=146s)
- [An incredible post I consulted for fixing SSH not working!](https://askubuntu.com/questions/1161579/ssh-server-cannot-be-found-even-though-installed)
- [Nice website that gave me for documentation about Port Forwarding.](https://nsrc.org/workshops/2014/sanog23-virtualization/raw-attachment/wiki/Agenda/ex-virtualbox-portforward-ssh.htm)

