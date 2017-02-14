#-------------------------------------------------------#
#  A network test script file for bash                  #
#  JMS :: 03.02.2010 :: Edited 03.02.2010               #
#-------------------------------------------------------#

#! /bin/bash

echo "Netowork Check: Moe, Burns, Snowball, Sideshow, Todd & Patty"
echo "Wait a few minutes for results (100 pings for each server)"
ping -c 100 -q moe&
ping -c 100 -q burns&
ping -c 100 -q snowball&
ping -c 100 -q sideshow&
ping -c 100 -q todd&
ping -c 100 -q patty&
