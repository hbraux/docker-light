#!/bin/bash

function _setup {
  [[ -f .setup ]] && return
  sed -i 's/^#jobmanager.web.address:.*/jobmanager.web.address: 0.0.0.0/' conf/flink-conf.yaml
  sed -i 's~^# io.tmp.dirs: /tmp*~io.tmp.dirs: /data~' conf/flink-conf.yaml
  if [[ $HEAP == low ]]; then 
    sed -i 's/heap.size: 1024m/heap.size: 512m/g' conf/flink-conf.yaml
  fi
  sed -i 's/^# state.backend.incremental:.*/state.backend.incremental: true/' conf/flink-conf.yaml
  echo "state.checkpoints.num-retained: $CHECKPOINTS_RETAINED" >>conf/flink-conf.yaml
  echo "state.backend.rocksdb.checkpoint.transfer.thread.num: 2" >>conf/flink-conf.yaml
  touch .setup
}


function _start {
  _setup
  # load the env
  . /opt/flink/bin/config.sh
  TMSlaves start
  exec bin/jobmanager.sh start-foreground
  
}

function _submit {
  shift
  jar=$1
  shift
  if [[ $1 == -c ]]; then
    shift
    mainclass=$1
    shift
    flink run -c $mainclass $jar $@
  else
    flink run -d $jar $@
  fi
}


case $1 in
  start)   _start;;
  submit)  _submit $@;;  
  *)       exec $@;;
esac

