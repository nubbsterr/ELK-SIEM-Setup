#!/bin/bash
# shrimple script to start up the entire elastic server
sudo systemctl start elasticsearch
sudo systemctl start filebeat
sudo systemctl start kibana
