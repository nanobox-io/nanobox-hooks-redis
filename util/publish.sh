#!/bin/bash

stability=$1

util_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(dirname $util_dir)"

# ensure the build dir exists
mkdir -p $project_dir/.build

echo "Generating tarball..."
tar -cvz -C $project_dir/src -f $project_dir/.build/redis-${stability}.tgz .

echo "Generating md5..."
cat $project_dir/.build/redis-${stability}.tgz | md5 > $project_dir/.build/redis-${stability}.md5

echo "Uploading builds to s3..."
aws s3 sync \
  $project_dir/.build/ \
  s3://tools.nanobox.io/hooks \
  --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
  --region us-east-1

echo "Cleaning..."
rm -rf $project_dir/.build
