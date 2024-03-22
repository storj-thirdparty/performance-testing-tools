#!/bin/bash

# vars
TARGET_DIR=~
ACCESS=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_ENDPOINT=
PARALLEL=24
TESTBUCKET=



# install tools
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
apt-get install -y zip bmon awscli curl speedtest
curl -L https://github.com/storj/storj/releases/latest/download/uplink_linux_amd64.zip -o uplink_linux_amd64.zip
unzip -o uplink_linux_amd64.zip
sudo install uplink /usr/local/bin/uplink


# config tools
aws configure set default.s3.multipart_threshold 60MB
aws configure set default.s3.multipart_chunksize 60MB
aws configure set default.s3.max_concurrent_requests $PARALLEL
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY

uplink access import default $ACCESS


# make test data
dd if=/dev/urandom of=testfile10G.bin iflag=fullblock bs=1G count=10
dd if=/dev/urandom of=testfile50G.bin iflag=fullblock bs=1G count=50
dd if=/dev/urandom of=testfile100G.bin iflag=fullblock bs=1G count=100

# take baseline
speedtest --accept-gdpr --accept-license

### run tests
## aws
# upload
time aws s3 cp testfile10G.bin s3://$TESTBUCKET --endpoint-url=$AWS_ENDPOINT
time aws s3 cp testfile50G.bin s3://$TESTBUCKET --endpoint-url=$AWS_ENDPOINT
time aws s3 cp testfile100G.bin s3://$TESTBUCKET --endpoint-url=$AWS_ENDPOINT

# download
time aws s3 cp s3://$TESTBUCKET/testfile10G.bin $TARGET_DIR --endpoint-url=$AWS_ENDPOINT
time aws s3 cp s3://$TESTBUCKET/testfile50G.bin $TARGET_DIR --endpoint-url=$AWS_ENDPOINT
time aws s3 cp s3://$TESTBUCKET/testfile100G.bin $TARGET_DIR --endpoint-url=$AWS_ENDPOINT


## cleanup storj
uplink rm sj://$TESTBUCKET/testfile10G.bin
uplink rm sj://$TESTBUCKET/testfile50G.bin
uplink rm sj://$TESTBUCKET/testfile100G.bin



## uplink
# upload
time uplink cp testfile10G.bin sj://$TESTBUCKET -p $PARALLEL 
time uplink cp testfile50G.bin sj://$TESTBUCKET -p $PARALLEL 
time uplink cp testfile100G.bin sj://$TESTBUCKET -p $PARALLEL

## cleanup storj
rm -f testfile10G.bin
rm -f testfile50G.bin
rm -f testfile100G.bin


# download
time uplink cp sj://$TESTBUCKET/testfile10G.bin $TARGET_DIR -p $PARALLEL
time uplink cp sj://$TESTBUCKET/testfile50G.bin $TARGET_DIR -p $PARALLEL
time uplink cp sj://$TESTBUCKET/testfile100G.bin $TARGET_DIR -p $PARALLEL
