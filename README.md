# ELK-SIEM-Setup
A guide for building your own SIEM using the Elasticsearch, Beats, and Kibana, and how to simulate, analyze and triage attacks for a homelab. Courtesy of the internet and other sources.

# A Very Friendly Warning
Given that this is still being developed, nothing is final. If you are going step-by-step in this guide assuming its <strong>unfinished form</strong> (that is, using this guide before it is totally complete), be warned that you may do either 1) Ruining the final build or 2) Unneeded time wasting steps.

That is all :)

# Preface
<strong>Big</strong> thank you to all of the lovely sources on the internet. I am not one to shy away from reading documentation but this kind of project is virutally impossible for me given my limited knowledge of the Elastic 'technologies'.

As stated above, there are many sources I consulted, all of which will be linked below for your own reading. The following will be a step-by-step guide of me <strong>creating my own SIEM</strong> using Oracle VirtualBox and namely Elastissearch, Beats and Kibana for indexing/analyzing, ingesting and visualizing our log data respectively.

This guide is aimed to be very step-by-step oriented; I guide you through everything as well as I can. If you do have questions, feel free to message me on Discord (nubbieeee) or email me (sherm5344@gmail.com)! Also massive shoutout to [crin](https://www.youtube.com/@basedtutorials/videos) for getting <strong>me</strong> properly started in cybersec. Without him, I would probably be aimlessly doing programming projects or frying my ESP32.

Furthermore, please check out the <strong>[Sources section](#sources)</strong> of this guide for any minor comments and important documentation. Sources are listed in a pseudo-priority order; ordered in what I consider is most important to consult if you wish to seek info regarding certain topics of this guide. 

Lastly, I do expect some amount of competence with a Linux terminal for this project. We will be using SSH, lots of `sudo` and command-line text editors. Naturally, I will guide you as much as I can, and whatever I cannot guide you through or struggle with can either be: 
1. Voiced to me. Yes, you can message me on Discord or via email. 
2. Googled and/or understood with AI. I won't shove it down your throat, but ChatGippity is marvelous for these roles of teaching the unknown. Of course, it is advised to do your own research and pay attention to the AI's responses for hallucination(s).

With that being siad, if you would like to contribute to this repo, feel free to message me or make a PR to the repo!

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
![Port forwarding in VirtualBox.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/forwarding-rule.png)
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
Install filebeat by running `sudo apt install filebeat -y`. As seen withboth Kibana and Elasticsearch, we will need to edit filebeat's YML file; `/etc/filebeat/filebeat.yml`, which I will go ahead and open with vim as I have been doing thus far.

Here's where things get interesting for us. We can add a TON of different inputs for filebeat, ranging from `journald` logs to yes, `winlog input`. We can actually get Windows event logs using filebeat. Simply put, `Winlogbeat` captures far more log data with Windows operations past just logged events. Event logs are available from `winlog input` but also `Winlogbeat`. For simplicity sake, we will use filebeat instead of Winlogbeat for our mock attack, and you will see why once I get to describing the attack :)

Therefore, we will make the following edits:
1. Add a new configuration to the `filebeat.inputs` field. This `winglog` input will require Script Block Logging on our Windows machine to work effectively, but we will configure that soon enough. The event IDs 4104 (script logging), 4105 (powershell cmd executed) and 4106 (powershell cmd complete) are all going to be very nice to have assuming an attack via PowerShell! <strong>This only works for PowerShell 5.1. If PowerShell is any greater version we need to change the `name` property to `PowerShellCore/operational` in accordance to MS Documentation.</strong>
![Winlog input to add alongside base inputs.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/winlog-config.png)
2. Configure the Elasticsearch portion of Filebeat. Kibana's config is totally fine. All we need to do is change the IP of the Elasticsearch host.
![Elasticsearch-Filebeat configuration.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/elastic-filebeat-config.png)

That is all we need to do. Our next step is to literally set up Filebeat in the terminal. This will manage how index management w/ Elasticsearch works, on top of disabling Logstash for log ingest.

Run `sudo filebeat setup --index-management -E output.logstash.enabled=false 'output.elasticsearch.hosts=["ELASTICSEARCH_HOST_IP_ADDRESS:9200"]'`. ELASTICSEARCH_HOST_IP_ADDRESS is the host IP address we chose in our elasticsearch.yml file. Index management manages how Elasticsearch goes about its indexing business, which I will not go over since that'd take 10 krillion years. `-E` overwrites specifc config settings, which we do next by 1) Disabling Logstash and 2) Ensuring we have our Elasticsearch host correctly set because why not.

Once that's over we can actually start everything up in the following order if NOT ALREADY STARTED:
1. Start Elasticsearch: `sudo systemctl start elasticsearch`
2. Start Filebeat: `sudo systemctl start filebeat`
3. Start Kibana: `sudo systemctl start kibana`
![Everything looks good!](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/all-services-running.png)

Assuming nothing blew up, we can now run one last `curl` to actually check if Elasticsearch is getting something from Filebeat. Run `curl --get http://ELASTICSEARCH_HOST_IP_ADDRESS:9200/_cat/indices?v`. This command may look insane, but it's relatively simple:
1. `_cat/indices` is the CAT Indices API. Simply put, it is an API that returns high level information about indices in an Elasticsearch cluster. We are making an API call with this URL.
2. `?v` = verbose. Gives column headers to output and makes it more readable. 

Now if you're a complete dumby like me, and forgot to run `sudo filebeat setup`, then we're DOOMED! Not. Just shutdown filebeat, run the setup command, and restart filebeat with the following order:
1. `sudo systemctl stop filebeat.service`, <strong>this took a while so do NOT Ctrl+C and possibly ruin your day.</strong>
2. `sudo filebeat setup --index-management -E output.logstash.enabled=false 'output.elasticsearch.hosts=["ELASTICSEARCH_HOST_IP_ADDRESS:9200"]'`
3. `sudo systemctl restart filebeat.service` && `sudo systemctl status filebeat.service`
![IT WORKS!???????????????!](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/filebeat-success.png)

That yellow healthcheck notice is nothing to worry about. To my knowledge, it is indicating that replica shards are unassigned, which basically means we are at risk of data loss, which we don't care about in our current state. No only that, we have no primary shards, since we have no indexed data, so <strong>we do not care.</strong>

With that being said, we're done here! To shut everything down, run:
1. `sudo systemctl stop kibana.service`
2. `sudo systemctl stop filebeat.service`, <strong>this took a while so, once again, do NOT Ctrl+C.</strong>
3. `sudo systemctl stop elasticsearch.service`

If you aren't leaving, then we'll get going to the next step; establishing a CA.

# Intermission: Establishing Elastic component IPs and Understanding CAs
Our first step with making a CA is to understand why we are doing it. We are making a CA so we can implement TLS, thus HTTPS into our Elastic components, and that requires certificates.

Firstly, we need to specify the instances of our services so we can later grant them a certificate. Navigate to `/usr/share/elasticsearch` and create a file called `instances.yml` by running `sudo touch instances.yml` and then opening it in a text editor. This file will hold information regarding what Elastic components we are using and their host IPs.
![Creating the file in the directory.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/creating-instances-yml.png)

Great stuff, let's add the following text that I will not copy because it is too tiresome:
![instances.yml configuration.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/instances-yml-config.png)

Replace the `10.0.2.15` with your appropriate host IP. You may be wondering what that `fleet` service is; it is for managing your fleet of Elastic Agents, which themselves collect all sorts of information past log data. Simply put, they are fundamental if you wish to set up Elastic Agents later down the line.

Save the file and exit our text editor. Our next step is to literally create a PKI (Public Key Infrastructure) for ourselves. To do so, we will need keys and certificates, and of course, a certificate authority, which we will make using Elasticsearch's utilities.

# Creating the CA and Generating Certificates
Navigate to `/usr/share/elasticsearch` and run the following: `sudo /usr/share/elasticsearch/bin/elasticsearch-certutil ca --pem`. Elasticsearch-certutil will aid use with creating basic [X.509](https://www.techtarget.com/searchsecurity/definition/X509-certificate) certificates as well as signing them. The `ca --pem` bit will 1) Create a new CA and 2) Create the CA certificate and private key in PEM format, as the command output will say. <strong>Leave the option for the output file blank; simply click Enter and continue.</strong>
![Running the command and seeing the output!](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/elastic-certutil-success.png)

Awesome sauce. We now have a zip file of our our CA certificate and private key. Unzip the zip folder with `sudo unzip ./elastic-stack-ca.zip`. You should have a `ca/` directory with a certificate file and private key. Our next step is to generate the certificate to sign for each of our instances.

Generate the certificate with the following command: `sudo /usr/share/elasticsearch/bin/elasticsearch-certutil cert --ca-cert ca/ca.crt --ca-key ca/ca.key --pem --in instances.yml -- out cert.zip`. Let me make this shrimple to understand:
1. We use the certutil and assign the CA certificate and private key from our unzipped files.
2. Everything is set to the PEM format, given the `--pem` option.
3. `--in instances.yml` is going to effectively use each instance specified in `instances.yml` and generate its certificate, private key and the CA certificate.
4. Output the final compressed zip with the name `certs.zip`.
![Creating our certificates for each instance.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/creating-instances-certificates.png)

The command output on its own does a great job giving a ton of documentation, which is awesome. We'll unzip the zip folder and then make a new directory `certs` solely to organize our goodies. Run `sudo unzip certs.zip` then `sudo mkdir certs`. We'll move all of our cert files into this directory with the following commands:
1. `sudo mv /usr/share/elasticsearch/elasticsearch/* certs/`
2. `sudo mv /usr/share/elasticsearch/kibana/* certs/`
3. `sudo mv /usr/share/elasticsearch/fleet/ * certs/`

Next, we will create directories to store the CA certificate and private key for each of our services:
1. `sudo mkdir -p /etc/elasticsearch/certs/ca`
2. `sudo mkdir -p /etc/kibana/certs/ca`
3. `sudo mkdir -p /etc/fleet/certs/ca`

Then we copy the private key and CA certificate:
1. `sudo cp ca/ca.* /etc/elasticsearch/certs/ca`
2. `sudo cp ca/ca.* /etc/kibana/certs/ca`
3. `sudo cp ca/ca.* /etc/fleet/certs/ca`

And finally, copy the service sertificates and keys we generated in the beginning to each `certs` directory:
1. `sudo cp certs/elasticsearch.* /etc/elasticsearch/certs/`
2. `sudo cp certs/kibana.* /etc/kibana/certs/`
3. `sudo cp certs/fleet.* /etc/fleet/certs/`

Last thing to do before moving on is to clean up our now empty directories as we have moved their contents to the above new folders: `sudo rm -r elasticsearch/ kibana/ fleet/`. 

# Intermission: Proper Security for SIEM Deployment
To be continued...

# Setting up Attack #1: Attack Story and Kill Chain Diagram
<strong>Under construction. This area is for my own personal notes for future steps of the project! Stay tuned :)</strong>

Script Block Logging needs to be enable in accordance to PS 5.1 documentation below. See sources for more info. (This is a note for myself, don't worry about it my gamer)

Will create Kill Chain diagram of attack in detail once this step is reached. 

Privilege escalation attempt on Windows using Windows Credential Manager and `cmdkey /list` 'vulnerability.' Started thru internal spearphishing from hacked coworker and was messaged about a potential PC issue requiring escalated privileges.

# Setting up Attack #2: Attack Story and Kill Chain Diagram
<strong>Under construction. This area is for my own personal notes for future steps of the project! Stay tuned :)</strong>

Suggested by chroma. 

# Sources
- [Official Elastic Docs on upgrading Elastic components. Highly recommend you consult both this and other sources if you wish to upgrade your lab.](https://www.elastic.co/guide/en/elastic-stack/current/upgrading-elastic-stack.html)
- [Official Elastic Docs on downloading Beats but also for adding the Elastic repo w/ APT or YUM.](https://www.elastic.co/guide/en/beats/filebeat/current/setup-repositories.html)
- [Ofiicial Elastic Docs on using certutil to create certificates for Elastic components.](https://www.elastic.co/guide/en/elasticsearch/reference/current/certutil.html)
- [Official MS Docs on Script Block Logging and PowerShell event IDs.](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_logging?view=powershell-5.1)
- [Official Elastic Docs on configuring winlog input for Filebeat.](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-input-winlog.html)
- [Official Elastic Docs regarding the cat indices API.](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/cat-indices.html#cat-indices-api-request)
- A whole lot of ChatGPT and Google Searching. It helps to know the 'why' behind what we're doing especially in cybersecurity!
- [Massive installation and setup guide which I consulted throughout my journey](https://www.leveleffect.com/blog/how-to-set-up-your-own-home-lab-with-elk?utm_source=chatgpt.com)
- [Consult this for VirtualBox downloads. Go straight to the wget command if you're on Ubuntu/Debian-based repos like me, or use my script to install VirtualBox lol](https://www.virtualbox.org/wiki/Linux_Downloads)
- [Consulted for a bug with VirtualBox download; USB enumerate.](https://www.youtube.com/watch?v=7Bdm_-JNiSc&t=146s)
- [An incredible post I consulted for fixing SSH not working!](https://askubuntu.com/questions/1161579/ssh-server-cannot-be-found-even-though-installed)
- [Nice website that gave me for documentation about Port Forwarding.](https://nsrc.org/workshops/2014/sanog23-virtualization/raw-attachment/wiki/Agenda/ex-virtualbox-portforward-ssh.htm)

