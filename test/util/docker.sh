
util_dir="$(dirname $(readlink -f $BASH_SOURCE))"
hookit_dir="$(readlink -f ${util_dir}/../../hookit)"
payloads_dir=$(readlink -f ${util_dir}/../payloads)

payload() {
  cat ${payloads_dir}/${1}.json
}

run_hook() {
  container=$1
  hook=$2
  payload=$3

  docker exec \
    $container \
    hookit $hook "$payload"
}

start_container() {
  name=$1
  ip=$2

  docker run \
    --name=$name \
    -d \
    -e "PATH=$(path)" \
    --cap-add=NET_ADMIN \
    --net=nanobox \
    --ip=$ip \
    --volume=${hookit_dir}/:/opt/gonano/hookit/mod \
    nanobox/redis:$VERSION
}

stop_container() {
  docker stop $1
  docker rm $1
}

path() {
  paths=(
    "/opt/gonano/sbin"
    "/opt/gonano/bin"
    "/opt/gonano/bin"
    "/usr/local/sbin"
    "/usr/local/bin"
    "/usr/sbin"
    "/usr/bin"
    "/sbin"
    "/bin"
  )

  path=""

  for dir in ${paths[@]}; do
    if [[ "$path" != "" ]]; then
      path="${path}:"
    fi

    path="${path}${dir}"
  done

  echo $path
}
