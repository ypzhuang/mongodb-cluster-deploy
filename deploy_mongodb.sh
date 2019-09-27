#!/bin/bash

manager=lr1tgr-centos-t3
work1=lr1tgr-centos-t1
work2=localhost.localdomain


NETWORK=$(docker network ls | grep mongo-network | awk '{print $2}')   
if [[ $NETWORK == "mongo-network" ]]; then
	echo "mongo-network created..."
else
	docker network create -d overlay  mongo-network
fi

docker node update --label-add mongo.replica=1  $(docker node ls -q -f name=$manager)
docker node update --label-add mongo.replica=2  $(docker node ls -q -f name=$work1)
docker node update --label-add mongo.replica=3  $(docker node ls -q -f name=$work2)


docker stack deploy  -c starter-mongodb-stack.yml mongo

echo -ne "\n\nWaiting for the mongdb cluster to be ready.."
function test_systems_available {
  COUNTER=0
  while ! nc -z 127.0.0.1 $1 ; do
  	printf '.'   
    sleep 2
    let COUNTER+=1
    if [[ $COUNTER -gt 20 ]]; then
       MSG="\nWARNING: Could not reach configured Mongodb on localhost:$1 \nNote: This script requires nc.\n"
       echo -e $MSG       
       exit 1
    fi
  done
}

test_systems_available 27017
test_systems_available 27018
test_systems_available 27019

docker exec -it $(docker ps -qf label=com.docker.swarm.service.name=mongo_mongo1) mongo  -u ${ROOT_USERNAME:-mongoadmin} -p ${ROOT_PASSWORD:-secret} --eval 'rs.initiate({ _id: "rs0", members: [{ _id: 1, host: "mongo1:27017" }, { _id: 2, host: "mongo2:27017" }, { _id: 3, host: "mongo3:27017" }], settings: { getLastErrorDefaults: { w: "majority", wtimeout: 30000 }}})'

docker exec -it $(docker ps -qf label=com.docker.swarm.service.name=mongo_mongo1) mongo  -u ${ROOT_USERNAME:-mongoadmin} -p ${ROOT_PASSWORD:-secret}  --eval 'rs.status()'

docker exec -it $(docker ps -qf label=com.docker.swarm.service.name=mongo_mongo1) mongo  -u ${ROOT_USERNAME:-mongoadmin} -p ${ROOT_PASSWORD:-secret} --eval 'rs.config()'


# docker run -it --rm mongo:4.0-xenial sh
# mongo  --host mongo2 -u mongoadmin -p secret
# docker volume rm  mongo_mongoconfig1 mongo_mongodata1
# docker volume rm  mongo_mongoconfig2 mongo_mongodata2
# docker volume rm  mongo_mongoconfig3 mongo_mongodata3


