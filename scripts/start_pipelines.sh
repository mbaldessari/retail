#!/bin/bash

build_ns=quarkuscoffeeshop-cicd
pipelines=('build-and-push-quarkuscoffeeshop-barista' 'build-and-push-quarkuscoffeeshop-counter' 'build-and-push-quarkuscoffeeshop-customerloyalty' 'build-and-push-quarkuscoffeeshop-customermocker' 'build-and-push-quarkuscoffeeshop-inventory' 'build-and-push-quarkuscoffeeshop-kitchen' 'build-and-push-quarkuscoffeeshop-web')

echo "Checking for resources to be available to start pipelines"
DELAY=5
retry=0
check=1
while [ "$check" == "1" ]; do
    sleep ${DELAY}

    for p in ${pipelines[@]}; do
        oc get -n $build_ns pipeline $p 1>/dev/null 2>/dev/null
        if [ "$?" != "0" ]; then
            echo "Error with pipeline $p, checking again"
            retry=1
            break
        fi
        retry=0
    done

    if [ "$retry" == "1" ]; then
        retry=0
        continue
    fi

    oc get -n $build_ns secret quay-auth-secret 1>/dev/null 2>/dev/null
    if [ "$?" != "0" ]; then
        echo "Error with secret quay-auth-secret, checking again"
        continue
    fi

    # Everything checks out, time to leave this look
    check=0
done

echo "Resources are all present, starting pipelines now"
# Start all the pipelines in the extra subdir with correct paramaters. Requires only oc.
for plr in $(ls charts/hub/quarkuscoffeeshop-pipelines/extra/*.yaml); do
    oc create -f $plr
done
