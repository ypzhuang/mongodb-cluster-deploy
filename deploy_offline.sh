#!/bin/bash
NETWORK=$(docker network ls | grep mongo-network | awk '{print $2}')   
if [[ $NETWORK == "mongo-network" ]]; then
	echo "mongo-network created..."
else
	docker network create -d overlay  mongo-network
fi

docker stack deploy --with-registry-auth -c offline-stack.yml offline
