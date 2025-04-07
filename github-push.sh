#!/bin/bash
# shrimple script to push to github instantly using bash aliases in ~/.bash_aliases

git add .
git commit -m "$1"
git push origin main
