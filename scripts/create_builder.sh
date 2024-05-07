#!/bin/bash

docker info

if [ $(docker buildx ls |grep -E "mbuilder.+running"|wc -l) -eq 0 ];then
    echo "Creating builder instance named mbuilder to support multi-architecure..."
    docker buildx create --name mbuilder --bootstrap --use
fi

docker buildx ls
