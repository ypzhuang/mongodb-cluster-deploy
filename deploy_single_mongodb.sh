#!/bin/bash

NETWORK=$(docker network ls | grep mongo-network | awk '{print $2}')
if [[ $NETWORK == "mongo-network" ]]; then
	echo "mongo-network created..."
else
	docker network create -d overlay  mongo-network
fi


docker stack deploy  -c starter-single-mongodb-stack.yml mongo
