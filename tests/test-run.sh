#!/bin/bash
export LANG=en
export LC_ALL=en_US.UTF-8
export MOCHA_PARALLEL="${MOCHA_PARALLEL:-4}"
#seting up env
command -v node >/dev/null 2>&1 || { curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash - && sudo apt-get install -qq -y nodejs; }
#command -v docker >/dev/null 2>&1 || { wget -qO- https://get.docker.com/ | sudo sh && sudo service docker start; }
command -v docker >/dev/null 2>&1 || { wget -qO- https://get.docker.com/ | sudo sh && echo 'DOCKER_OPTS="--storage-driver=devicemapper"' | sudo tee --append /etc/default/docker >/dev/null && sudo service docker start; }
command -v meteor >/dev/null 2>&1 || { curl https://install.meteor.com/ | sh; }
command -v parallel >/dev/null 2>&1 || { sudo apt-get -qq -y install parallel; }

#running a single test
function run_test {
    DOCKER_ID=$(sudo docker run --privileged=true -d -t mybase /sbin/my_init)
    sleep 5
    export PROD_SERVER_USER=root
    export PROD_SERVER=$(sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' $DOCKER_ID)
    cd ~/meteor-up
    npm test -- -g $1
    sudo docker rm -f $DOCKER_ID > /dev/null
}
export -f run_test

MUP_DIR=~/meteor-up
{
rm -rf /tmp/tests
cp -rf $MUP_DIR/tests /tmp
cd /tmp/tests/
rm -rf new*
echo '' > ~/.ssh/known_hosts
ssh-keygen -f new -t rsa -N ''
eval `ssh-agent` 
ssh-add new 
sudo docker rm -f $(docker ps -aq) 2>/dev/null
sudo docker build -t mybase .

cd $MUP_DIR
npm install
sudo npm link
} > /dev/null
parallel --progress -j $MOCHA_PARALLEL run_test ::: </tmp/tests/tests.list
