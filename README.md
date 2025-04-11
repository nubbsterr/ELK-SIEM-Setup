# Elastic-SIEM-Setup
A guide for building your own SIEM using the Elasticsearch, Beats, and Kibana, and how to simulate, analyze and triage attacks for a homelab. Courtesy of the internet and other sources.

# A Very Friendly Warning
Given that this is still being developed, nothing is final. If you are going step-by-step in this guide assuming its <strong>unfinished form</strong> (that is, using this guide before it is totally complete), be warned that you may 1) ruin your final build or 2) waste a lot of time on unneeded steps or 3) have to restart like I did because of a funny mistake.

That is all :)

# Preface
<strong>Big</strong> thank you to all of the lovely sources on the internet. I am not one to shy away from reading documentation but this kind of project is virutally impossible for me given my limited knowledge of the Elastic 'technologies'.

As stated above, there are many sources I consulted, all of which will be linked below for your own reading. The following will be a step-by-step guide of me <strong>creating my own SIEM</strong> using Oracle VirtualBox, Elastissearch, Beats and Kibana for indexing/analyzing, ingesting and visualizing our log data respectively.

This guide is aimed to be very step-by-step oriented; I guide you through everything as well as I can. If you do have questions, feel free to message me on Discord (nubbieeee) or email me (sherm5344@gmail.com)! Also massive shoutout to [crin](https://www.youtube.com/@basedtutorials/videos) for getting <strong>me</strong> properly started in cybersec. Without him, I would probably be aimlessly doing programming projects or frying my ESP32.

Furthermore, please check out the <strong>[Sources section](#sources)</strong> of this guide for any minor comments and important documentation. Sources are listed in a pseudo-priority order; ordered in what I consider is most important to consult if you wish to seek info regarding certain topics of this guide. 

Lastly, I do expect some amount of competence with a Linux terminal for this project. We will be using SSH, lots of `sudo` and command-line text editors; I expect you to be comfortable with common Linux commands like `cd`, `mkdir`, `systemctl`, etc. Naturally, I will guide you as much as I can, and whatever I cannot guide you through or struggle with can either be: 
1. Voiced to me. Yes, you can message me on Discord or via email. 
2. Googled and/or understood with AI. I won't shove it down your throat, but ChatGippity is marvelous for these roles of teaching the unknown. Of course, it is advised to do your own research and pay attention to the AI's responses for hallucination(s).

With that being siad, if you would like to contribute to this repo, feel free to message me or make a PR to the repo!

# SIEM Features
<strong>Basic features</strong> should include:
- Log ingestion and indexing
- Log parsing/querying
- Dashboards
- Alerts

Other features like event correlation, root cause analysis, ML and whatnot are achieved in more advanced software like EDRs and XDRs, which we will not be making anytime soon.

# What You Will Learn!
By the end of this project, <strong>you are going to know a lot of stuff</strong>; you'll have basically done a fair portion of what a SOC analyst does in their like:
- Understand the workings of a SIEM, from ingest to visuallizing the data.
- Understand how Elasticsearch, Beats and Kibana work together to create a SIEM.
- Understand what a [CA](https://en.wikipedia.org/wiki/Certificate_authority) is, the signing process, and how SSL certificates function.
- Establish simulated attacks in a controlled environment and employ root cause analysis.
- Understand [MITRE ATT&CK](https://attack.mitre.org/) and using it to show TTPs of an attack.
- Understand the [Kill Chain framework](https://www.lockheedmartin.com/en-us/capabilities/cyber/cyber-kill-chain.html); understand the attacker POV.
- Understand incident response measures for triaging attacks.

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
4. We don't need a proxy, so we can skip configuring one. We also don't need an alternative mirror for Ubuntu, so leave everything there as is.
5. Continue setting up the storage config for the OS, there is no need to tinker with anything unless <strong>you</strong> want to :) ![Storage Conig](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/storage-config.png)
6. Confirm your user credentials and SSH setup, tick the OpenSSH Server Box. We don't need any featured software on our VM, so continue with the installation. ![Inputting user credentials, you can change yours to your liking!](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/profile-setup.png)
7. Wait for the OS install to complete :) ![](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/waiting-for-install.png)

Congrats! You're one step closer to a lovely homelab setup. Let's continue to our next step of our journey; installing and Configuring Elasticsearch.

# Installing and Configuring Elasticsearch
Before we even get to starting anything, go into your VirtualBox menu and select the 3 bars next to your VM, then select `Snapshots`. Click `Take` and name the snapshot however you like. Congratulations, you have just implemented a failsafe in case you break your VM somehow. <strong>I strongly recommend you regularly take snapshots of your VM when you reach checkpoints in this guide.</strong>

Once you reboot your system, wait for your log statements to stop, then press Enter. Continue to logging in as your user. When you're in, your screen should look something like this:
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

Run `sudo apt install apt-transport-https -y` and continue. Next we add the GPG key for Elasticsearch and its repo to our Ubuntu sources.

Run `wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -` to add the GPG key and `echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list` to see the repo in our ubuntu sources. 
![GPG and repo added!](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/gpg-repo-success.png)

Success! Update our packages then install elasticsearch. Run `sudo apt update -y && sudo apt install elasticsearch -y`.

Now that Elasticsearch is installed, we need to reload all running daemons and services on our VM. Since we are adding a new service (Elasticsearch), this is necessary. It wasn't needed for SSH since we changed nothing with configuration files, and configuration is already handled by apt (to my knowledge) but for Elasticsearch, we will be modifying our configuration files.

We will want to confirm that Elasticsearch is actually on our system, so run `sudo systemctl status elasticsearch.service`, we preferably want to see a 'dead' process.
![Yes I did a typo.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/elasticsearch-success.png)

Real talk, I included that typo to show that I am human just like you. Creating this guide is both for my learning and so you can get a lovely homelab setup to enjoy cybersec :) With that being said, we are officially finished the installation phase for Elasticsearch and will now get to configuring it.

# Configuring Elasticsearch and Testing It Out
This step is entirely for configuring Elasticsearch; telling it how to run, what ports it needs, communication, etc.

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

We will leave the `server.port` property alone as port 5601 is the default option and we have no need to edit it. We will edit the `server.host` and `server.name` properties to be our IP address and an appropriate name respectively. One thing you may notice is that you can adjust the credentials for accessing the Kibana server. You can leave them blank for now, as we will change them later on.
![Our edits.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/kibana-config.png)
![Default credentials are a big nono!](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/kibana-nono-security.png)

Save and exit our changes to the YML file and go ahead and start up the Kibana service. If you're like me and have Elasticsearch not enabled in systemd, you will need to start it up in the following order:
1. Start Elasticsearch w/ `sudo systemctl start elasticsearch` if not already started.
2. Start Kibana w/ `sudo systemctl start kibana`. We can also make Kibana run on boot w/ `sudo systemctl enable kibana`.

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

# Establishing Elastic Services IPs and Understanding Certificate Authorities
Our first step with making a CA is to understand why we are doing it. We are making a CA so we can implement [TLS](https://en.wikipedia.org/wiki/Transport_Layer_Security), thus HTTPS into our Elastic services, and that requires certificates.

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

Generate the certificate with the following command: `sudo /usr/share/elasticsearch/bin/elasticsearch-certutil cert --ca-cert ca/ca.crt --ca-key ca/ca.key --pem --in instances.yml --out cert.zip`. Let me make this shrimple to understand:
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
Fun fact, we are using `sudo` a fair bit to access stuff on our system given escalated privileges through authentication. Simply put, we input out password to edit most of our configs, since this is low level stuff yes? 

What if we hate using `sudo` and just want to edit everything? Well, we just use the root account all the time, then we don't need to worry about authenticating! <strong>No, no, no, no!!!!</strong> Bad! We want to employ least privilege on everything. As someone studying cybersecurity and even speaking with current analysts, systems are VERY susceptible to attacks; friggin' [PrintNightmare](https://nvd.nist.gov/vuln/detail/cve-2021-34527) everywhere. 

What we are going to do is just that; employ least privilege on our systems to each of our services to both 1) Enhance our security posture and 2) <strong>Practice the task of assigning least privilege.</strong>

We'll begin by navigating to `/usr/share` and run the following commands:
1. `sudo chown -R elasticsearch:elasticsearch elasticsearch/`, which will 1) Recursively set the ownership of the `elasticsearch` directory to Elasticsearch and 2) Change its group to the `elasticsearch` group, which will further allow us to limit the scope of Elasticsearch's permissions.
2. `sudo chown -R elasticsearch:elasticsearch /etc/elasticsearch/certs/ca`. Same stuff as above but now for Elasticsearch's CA copies, so it can access that directory as well.

<strong>Now I cannot make myself any clear that you must NOT do this `chown` privilege restriction to Kibana FOR ANY REASON. Kibana needs access to its CA files to serve the SIEM frontend in your web browser.</strong>

Now, to ensure our posture is correct and our certificates are valid, we will use the `openssl` command to print certificate information to the console with the following command: `sudo openssl x509 -in /etc/elasticsearch/certs/elasticsearch.crt -text -noout`, which will: 
1. Print information for X509 certificates.
2. `-in` specifies the certificate to check out
3. `-text`  ouputs everything as human-readable.
4. `-noout` suppresses the output of the encoded version of the certificate; only shows the human-readbale output above.
![Success.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/elastic-chown-success.png)

# Configuring The Services To Run HTTTPS w/ SSL Certificates
Now we are effectively ready to put everything together, and enable SSL on all of our services, thereby enabling HTTPS. 

Our first step is to go configure the `kibana.yml` configuration file in `/etc/kibana/` using a text editor, where we will copy the following massive text wall and paste it to the <strong>bottom</strong> of our YML file:

```
server.ssl.enabled: true
server.ssl.certificate: "/etc/kibana/certs/kibana.crt"
server.ssl.key: "/etc/kibana/certs/kibana.key"

elasticsearch.hosts: ["https://10.0.2.15:9200"]
elasticsearch.ssl.certificateAuthorities: ["/etc/kibana/certs/ca/ca.crt"]
elasticsearch.ssl.certificate: "/etc/kibana/certs/kibana.crt"
elasticsearch.ssl.key: "/etc/kibana/certs/kibana.key"

server.publicBaseUrl: "https://10.0.2.15:5601"

xpack.security.enabled: true
xpack.security.session.idleTimeout: "30m"
xpack.encryptedSavedObjects.encryptionKey: "min-32-byte-long-strong-encryption-key"
```

Fun fact, these are all properties inside of our YML file, but they are commented out, and addressing you to edit each and every property would be a pain. Some of these are very self explanatory and others are not the case. The `server.publicBaseUrl` property is our IP and Kibana port number (5601), which specifies where Kibana is available; basically our SIEM UI. The `xpack` bits are all for securing Elasticsearch. The `xpack.encryptedSavedObjects.encryptionKey` property is for creating an encryption key to encrypt and decrypt sensitive Kibana entities like dashboards, alerts, etc. We use the default specified by [Elastic](https://www.elastic.co/guide/en/kibana/current/xpack-security-secure-saved-objects.html), but if you guys find docs on this, PLEASE send them to me because I cannot find many examples for this property.

The rather confusing matter in all of this is specifying the `elasticsearch.ssl.key/certificate` properties with our kibana key/certificate. Initially, I was very confused on why we (the LevelEffect Guide linked in Sources) was using the Kibana certificate and key here, but the answer is LITERALLY in the YML file comments. We are SENDING the Kibana certificate and key TO Elasticsearch to VERIFY our identity as Kibana. That is it. And here I was, scrabbling in the dirt for 10 minutes trying to find an answer xD

Anyways, remember to replace the `10.0.2.15` with your host IPs from before. Save and exit, then open the `elasticsearch.yml` configuration file in `/etc/elasticsearch/` and paste the following to the bottom of your YML file:

```
xpack.security.enabled: true
xpack.security.authc.api_key.enabled: true

xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.key: /etc/elasticsearch/certs/elasticsearch.key
xpack.security.transport.ssl.certificate: /etc/elasticsearch/certs/elasticsearch.crt
xpack.security.transport.ssl.certificate_authorities: ["/etc/elasticsearch/certs/ca/ca.crt"]

xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.verification_mode: certificate
xpack.security.http.ssl.key: /etc/elasticsearch/certs/elasticsearch.key
xpack.security.http.ssl.certificate: /etc/elasticsearch/certs/elasticsearch.crt
xpack.security.http.ssl.certificate_authorities: ["/etc/elasticsearch/certs/ca/ca.crt"]
```

For the sake of length and explanation, I will leave [a link to documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-settings.html#token-service-settings) for you to read. The summary for these settings is that we are enabling a gajillion security features and settings for our setup, particularly to use SSL.

You will 110% notice that we have no quotation marks with each filepath here, and that is, in fact, the correct method to display them here. I believe this is simply a matter of parsing behind the scenes, but it is undeniably a <strong>terrible one.</strong> The `certificate_authorities` list needing quotation marks makes sense, but wadahek Elastic? Were the devs chugging Red Bull while making the backend for this?

Save and exit as usual, and we are ready to load our new configurations to officially enable SSL for our services. If you recall from before, we need to restart our services to enable new configurations by running `sudo systemctl restart <service_name>`. `restart` will both start the system if it is not running and restart it, so we can go ahead and do just that for both Elasticsearch and Kibana:

1. `sudo systemctl restart elasticsearch`
2. `sudo systemctl restart kibana`

If you're not like me and had a typo in their `elasticsearch.yml` config and panicked whem everything blew up in my face for like 10 minutes (I forgot to specify the SSL CERTIFICATE BRO), you should have everything running just fine. Run `sudo systemctl status <elasticsearch or kibana>` if you wanna check the status of either service, though we can be certain they are running at the moment.

We don't need `filebeat` running for this next step. Our last check to ensure everything is in order is to `curl` the HTTPS host for Elasticsearch, which in my case is: `curl --get https://10.0.2.15:9200`. Replace your IP as needed, anddd....
![Erm... What?](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/curl-fail.png)

"Nubb you damn fraud, this don't work! I quit!!!!!"

<strong>Noooooooooooo!</strong> Firstly, don't quit easy like that. Secondly, the reason why `curl` failed like this is because our browser does not trust the certificate just yet, or rather, the CA. We can bypass this temporarily and just add the `--insecure` parameter to end of our `curl` command and pipe the output to `jq` to make it nice and pretty as JSON format: `curl --get https://10.0.2.15:9200 --insecure | jq`.
![Yippee!](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/curl-success.png)

Nice, we at least got something! To summarize this output, we require credential to log into Elasticsearch, which we will generate in the next step of our guide. But for now, go ahead and pat yourself on the back; we've got SSL running and security enabled! One step closer to a real homelab setup. We can stop our services by running `sudo systemctl stop kibana` then `sudo systemctl stop elasticsearch`. 

# Generating Authentication Credentials For Elasticsearch
To generate credentials, we will use the [elasticsearch-setup-passwords](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-passwords.html) utility to do so. Documentation is hyperlinked as always for your reading. Simply put, the utility will generate passwords for a cluster and connect via HTTPS using our previously defined `xpack.security.http.ssl` in our `elasticsearch.yml` file. 

Run `sudo /usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto` to randomly generate passwords, set the passwords of select users, and output them to the console. Make sure Elasticsearch is running before you do this or else you will get an error. You will see many passwords and names associated with them. For example, `apm_system` is the [APM or Application Performance Montioring System](https://www.elastic.co/guide/en/observability/current/apm.html), which, per its name, collects performance metrics for services and applications running in real-time, and is built on the Elastic Stack. More information about these users can be collected here by [Elastic's official documentation.](https://www.elastic.co/guide/en/elasticsearch/reference/current/built-in-users.html)

We only need the `kibana_system` password as that is how we will log in to our frontend UI and access our SIEM. Authentication to Elasticsearch is proxied by Kibana as well, so we can get away with doing this just fine. Open the `kibana.yml` file in `/etc/kibana/` with a text editor and find the `elasticsearch.username` and `elasticsearch.password` properties. Change the `elasticsearch.password` to the password we just generated and <strong>DO NOT CHANGE THE `elasticsearch.username` PROPERTY. You will get error logs back when the server attempts to launch to host the frontend!</strong>

Save and exit our YML config file and restart Kibana so that our new configuration settings are read properly with `sudo systemctl restart kibana && sudo systemctl restart elasticsearch`.

And with that, we are ready to log into our SIEM frontend for the first time!

# Logging into Elastic
Firstly, start up Elasticsearch and Kibana if you haven't already with `sudo systemctl start elasticsearch`, `sudo systemctl start kibana` and `sudo systemctl start filebeat`. The fun part starts now.

Secondly, we can't actually access our frontend just yet. We actually need to create a port forwarding rule, Fun fact, `10.0.2.15:5601` is hosted on the SERVER, but not publicly accessible to US. We need to redirect, or otherwise, <strong>forward</strong>, the traffic to us so we can recieve it.

Open your Network settings as we did long ago to configure SSH's port forwaring. Create a new rule with the little 'Plus' icon on the right with the following specifications:
- Protocol: TCP
- Host IP: 127.0.0.1 
- Host Port: 5601
- Guest IP: `YOUR_KIBANA_IP`
- Gust Port: 5601

`YOUR_KIBANA_IP` is the IP you are hosting the Kibana server on, which is shown in both Kibana's log files and the `kibana.yml` configuration. Once you've created the rule, you can attempt to head to your frontend in your web browser at `https://127.0.0.1:5601` if your VM is powered on and your services are running.
![Waiting....](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/frontend-loading.png)

The loading may take a while; just be patient...
![A FRONTEND????????????](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/frontend-loaded.png)

Many hours, days, a VM restart, and many sweaty, hair-pulling moments have finally led both me and <strong>you</strong> to this moment! We have a frontend!

# Understanding Fleet and Creating a Fleet Server
To be continued...

# Intermission: Setting up a Kali Linux VM w/ VirtualBox
I intended to have this (a Kali VM) to be used for one of the incidents below. However, that won't be needed since we really only need a Windows VM/System and Linux VM/System. Ensure you have either OS and are comfortable with interacting with your host OS for the simulated incidents.

1. Go to [here](https://www.kali.org/get-kali/#kali-virtual-machines) to get a prebuilt kali vm.
2. Unpack the download w/ `7z x downloadedacrhive.7z`. If needed, install `p7zip` on Ubuntu/Debian w/ `sudo apt install p7zip-full` which provides us with the extraction tooling. Run `sudo apt update` before installing. <strong>This will take a while.</strong>
3. Go to VirtualBox and Click 'Add' and select the extracted Kali VirtualBox folder.
4. Start the VM and input 'kali' as both your username and password.

Congrats, you have a Kali Linux VM running! Run the following commands to update your packages:
1. `sudo apt update`, to check for updates and updatable packages.
2. `sudo apt upgrade`, upgrade packages found in the previous command.
3. `sudo apt autoremove`, remove any unneeded dependencies for packages to clean up a lil.

# Intermission: Setting up a Windows 10 VM w/ VirtualBox
1. Go get [a multi-edition Windows 10 ISO](https://www.microsoft.com/en-us/software-download/windows10ISO) here. Pick your lnaguage as needed and wait for the download to complete.
2. Go to `Machine` --> `New` and select `Microsoft Windows` and `Windows 10 (64-bit)` as your Type and Version respectively. Select the previously installed Windows 10 ISO as your ISO image. Check the box to skip the 'Unattended Install' as well.
![Windows VM Config](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/windows=vm-config.png)
3. Set up your system resources as you wish. Refer to the original Ubuntu VM setup instructions as needed. I have my VM set to run 4GB of RAM and 2 vCPUs/Processors.
4. Set storage for your Virtual Hard Disk; I have allocated 50GB of space.

Our Windows VM is now complete. We can now start it up and proceed to setting up Windows. To keep it short and sweet, simply follow the installer's instructions; <strong>when you are prompted for a product key, click the 'I don't have a product key' prompt.</strong>

We'll be installing Windows 10 Home, no special stuff here. Make sure to select the 'Custom: Install Windows Only' prompt when you reach the below step.
![We want a clean install.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/windows-install-select.png)

Select the unallocated disk space, click 'Next', and wait for the install to complete :) Once the install finishes, Cortana will jumpscare you and the final bits of our Windows setup will commence; setting our region/country, keyboard layout, but most importantly, creating a Microsoft Account. <strong>The easiest way to skip this is to disconnect from the internet or Ethernet and attempt to go back to a previous step, then reconnect to the internet.</strong> This worked for me. Alternatively, you can input <strong>Shift + F10 to open the Command Prompt, then input `oobe/bypassnro`, which will reboot your system and effectively skip this step.</strong> I didn't try this myself, so let me know if it doesn't work and I will revamp this step as needed.

Otherwise, we can continue and make a Local Account with out desired credentials and set up security questions. Then we get to disable all of the spyware that Microsoft attempts to install or enable, <strong>say no to EVERYTHING.</strong> Cortana will annoy us once more before finally leaving us alone and letting the Windows install totally finish. 
![It's finally over...](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/screenshots/windows-success.png)

Additionally, once you load up Windows, you can debloat it using [the instructions in this lovely GitHub repo](https://github.com/Raphire/Win11Debloat). This will improve Windows' performance by removing random apps and disabling telemetry. The README will guide you through everything, as it did for me! Once you're done there, you should check for updates in Settings and install any and all security patches and whatnot.

# Intermission: Simulating Events in a Controlled Environment
The following 2 sections will go over running simulated incidents and triaging them through our SIEM. These sections are highly recommended to go through but totally optional! However, they will prove a fine amount of competence with root-cause analysis, incident response, how to triage attacks and how to map an incident with both the Kill Chain framework and MITRE ATT&CK Entreprise matrix. Simply put, there is a lot of info to unpack, but it is well worth your time!

Read through the attack story, understand the TTPs at play, and run through each pre-incident step in preparation for running the attack! When your ready, I will guide you through the incident; how to simulate, triage and respond to the incident in a professional manner.

# Incident #1: Attack Story, TTPS, Kill Chain Diagram and Incident Steps
Sally from Accounting sees an urgent email from her coworker (a similar, but fake email address!) that declares something is wrong with her device, requiring her to 1) Shut off Windows Defender and 2) Run a pre-configured script in her PowerShell terminal... 

Unbeknownst to Sally, the payload she runs in her PowerShell terminal opens a reverse shell on the attackers' machine. SOC was notified of Defender being shut off but also the script being ran in PowerShell. 

## MITRE Layout:
The MITRE Layout segments parts of the attack and associates them with their respective TTP(s) or Tactics, Techniques, and Procedures. This attack contains the following TTPs:

- Impersonation as coworker using fake email. [T1656](https://attack.mitre.org/versions/v14/techniques/T1656/) and [T1566](https://attack.mitre.org/techniques/T1566/).
- Listen on TCP port and open reverse shell. [T1204](https://attack.mitre.org/versions/v14/techniques/T1204/), [T1059.001](https://attack.mitre.org/techniques/T1059/001/) and [T1059.004](https://attack.mitre.org/techniques/T1059/004/).

## Pre-Incident Setup:
- Add `filebeat` input in `filebeat.yml` config to have `PowerShellCore/Operational` as name to support PowerShell >=7.4. Same `event_id` and `type`.
- Add `filebeat` input in `filebeat.yml` config to capture Windows Defender activity; being shut off/disabled. 
- Ensure log data is being sent to Elastic server.
- Ensure your Windows VM is updated and can run PowerShell.
- Know how to create a listener port on your machine; I will be using my host machine running Linux; run `nc -nvlp <port_number>` to listen on Linux.
- Ensure you are running NAT network connection on the VM in VirtualBox settings! Both machines should be on the same subnet as well (your host machine and the VM running it, in my case.)
- Ensure you can `ping` both machines. Ping Windows VM from host; host from Windows VM.
- <strong>Have the payload script ready with the given port and IP of the host machine you are listening on!</strong>

## Kill Chain Diagram, Made Using Excalidraw
![Kill Chain Diagram.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/killchains/ReverseShellKillChain.png)

## Incident Steps
To be continued...

# Incident #2: Attack Story, TTPS, Kill Chain Diagram and Incident Steps
An IEX exploit that results in a payload being downloaded and executed on a machine; installing an infostealer. Initial access done by phishing, asserting that a 0day security patch was supposed to be done by a fake IT/Help desk email by Scattered Spider (why not). Coworker deams it as a false positive but you investigate further and isolate the system from the network. You locate the infostealer program, which originally planned to exfil the data to a remote Discord server and delete it before it can do further damage.

## MITRE Layout:
The MITRE Layout segments parts of the attack and associates them with their respective TTP(s) or Tactics, Techniques, and Procedures. This attack contains the following TTPs:

- Posing as IT/Help Desk. [T1656](https://attack.mitre.org/versions/v14/techniques/T1656/).
- User executes IEX command per Help Desk's response. [T1204](https://attack.mitre.org/versions/v14/techniques/T1204/).
- Data is locally collected and stored locally. [T1074.001](https://attack.mitre.org/techniques/T1074/001/).
- Data exfilration to Discord server using internet (Discord on the Web). [T1020](https://attack.mitre.org/techniques/T1020/) and [T1567](https://attack.mitre.org/techniques/T1567/).

## Pre-incident Setup
- Make sure the Windows VM is updated and can run PowerShell.
- Have the payload script ready and configuring to download at the right website; TBD. 
- Ensure log data is being sent to Elastic server.

## Kill Chain Diagram, Made Using Excalidraw
![Kill Chain Diagram.](https://github.com/nubbsterr/ELK-SIEM-Setup/blob/main/killchains/IEX-IWRKillChain.png)

## Incident Steps
To be continued...

# Sources
- [MITRE ATT&CK Website for TTPs.](https://attack.mitre.org/)
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

