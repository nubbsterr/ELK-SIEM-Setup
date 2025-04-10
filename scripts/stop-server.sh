#!/bin/bash
# shrimple script to stop elastic server
sudo systemctl stop kibana
sudo systemctl stop filebeat
sudo systemctl stop elasticsearch
