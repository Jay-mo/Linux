#!/bin/bash

#this is a script that queries all the meraki shards and returns the CNAME, A and AAAA records for each shard
#if there are no values for these records it prints NONE.
#After 5 continous None Values the script stops running, as this is taken as an indication that there are not more shards.


#setting variables for the url
domain='meraki.com'

#setting variable that is used for a while loop.
loop_condition=true

#setting a variable that will be used to get shard number
count=1

#setting variable to track number of consecutive 
no_value=0


#using getops so that we can pass flags to the script.
#expected flag is -m . 
while getopts ":m:" opt; do
  case ${opt} in
    m ) # flag option m
        
        #setting a pattern to check the status of the DNS query.
        status_pattern='status: ([A-Z]*),'

        #run dig command on the domain name that is provided as an argument to the -m flag
        output=$(dig $OPTARG)

        #use regex to find a match for the pattern
        [[ $output =~ $status_pattern ]]

        #check if the status of the dns query is NOERROR

        if [[ ${BASH_REMATCH[1]} == 'NOERROR' ]]; then

            #get CNAME and A record.
            cname_value=$(dig $OPTARG | grep 'CNAME\s*[a-zA-Z0-9.]*' | cut -f 6)
            ip_value=$(dig $OPTARG | grep 'A\s\+[0-9.]\+' | cut -f 5)

            #print out the shard , CNAME and IP_address
            echo "$OPTARG CNAME: $cname_value, IP_ADDRESS: $ip_value"
        elif [[ ${BASH_REMATCH[1]} == 'NXDOMAIN' ]]; then
            echo "Kindly enter a correct domain"
        fi

        ;;


        
    #if wrong flag is passed, print the need flag for the script.
    \? ) echo "Usage: cmd [-m] machine-domain-name"
        ;;

    #if no argument is passed, print to user that a shard name is needed
    : ) 
    echo "Usage: cmd [-m] machine-domain-name"
    echo "-m requires a machine name"
esac
done

#if no flags are used, then script will run and print all CNAME and IP Address for all shards
if [ $# -eq 0 ]; then

    #while loop that will run till we get 5 consecutive None values.
    while [ loop_condition ]; do
        

        #a variable for the shard name
        shard="n$count.$domain"


        #getting cname
        cname_value=$(dig $shard | grep 'CNAME\s*[a-zA-Z0-9.]*' | cut -f 6)

        #getting cname
        if [ -z $cname_value ]; then
            cname_value=$(dig $shard | grep 'CNAME\s*[a-zA-Z0-9.]*' | cut -f 5)

        fi

        #getting IP address
        ip_value=$(dig $shard | grep 'A\s\+[0-9.]\+' | cut -f 5)

        
            
        #increasing count variable to track shard number
        ((count++))

        #if the values of cname and ip address are empty print the values of None.
        if [ -z $cname_value -a -z $ip_value ]; then
            #increasing no_value variable to track consecutive None values.
            ((no_value++))
            echo "$shard  CNAME: None, IP_ADDRESS: None"

            #after 5 consecutive None values , break out of loop.
            if [ $no_value -gt 5 ]; then
                echo 'There are no more shards'
                break
            fi
        else

        #print values of CNAME and IP_address 
            echo "$shard  CNAME: $cname_value, IP_ADDRESS: $ip_value"
            no_value=0
        fi
    done

fi