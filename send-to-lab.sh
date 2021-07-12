#!/bin/sh

# this is just something for myself, you can ignore it

echo "deleting older packages"
rm -rf packages/*
make clean package -j

echo "moving to the lab"
mv packages/* ~/Documents/GitHub/Repository/lab/debs/

echo "creating a new substance"
rm -rf ~/Documents/GitHub/Repository/lab/Packages*
cd ~/Documents/GitHub/Repository/lab/
./scan-packages.sh

echo "echo uploading the new substance to the laboratory"
cd ../
git add .
git commit -m "added new beta packages"
git push -u origin main

echo "done"