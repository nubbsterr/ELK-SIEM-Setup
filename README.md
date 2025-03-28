# ELK-SIEM-Setup
A guide for building your own SIEM using the ELK stack, and how to simulate, analyze and triage attacks. Courtesy of the internet and other sources.

# Preface
<strong>Big</strong> thank you to all of the lovely sources on the internet. I am not one to shy away from reading documentation but this kind of project is virutally impossible for me given my limited knowledge of the ELK stack.

As stated above, there are many sources I consulted, all of which will be linked below for your own reading. Past that, the following will be a step-by-step guide of me <strong>creating my own SIEM</strong> using said sources as a guide. 

# SIEM Features
<strong>Basic features</strong> should include:
- Log ingestion (mainly network-related logs and OS log data for initial testing. Filebeat and/or Logstash can be used for ingest.)
- Log parsing/querying (KQL can easily query for us, parsing is done by Logstash)
- Dashboards (Kibana duh)
- Alerts (Achieved inside the actual SIEM UI)

You may notice that I did not include retention, and that is because I do not plan to retain data for this solution. This is made for a homelab setp; not a production environment where retention is necessary to trash malicious behaviour.

# The Setup Begins
This is our first step into our SIEM-building journey. 

I will update this once I actually get going given enough research. Stay tuned :))))

# Sources
- (will be added at the end of the project ofc)
