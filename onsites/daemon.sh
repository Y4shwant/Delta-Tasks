#!/bin/bash
set -x
log_file="/var/log/daemon.log"
specified_threshold=200

start_daemon(){
    daemon &
    PID=$!
    echo "$PID" > /tmp/daemondelete.log 
    echo "daemon started successfully"   
}
stop_daemon(){
    kill  $(cat '/tmp/daemondelete.log') 2>/dev/null
    echo "daemon stopped successfully"
}



daemon(){
    declare -A networks
    declare -A runtime
    while true; do
        inp=`docker ps --format "{{.ID}} {{.Networks}}"`
        while IFS= read -a containers; do
            for i in ${container[@]}; do
                IFS="+" read -a containers_split <<< "$i"
                networks[${containers_split[1]}]+="$containers_split[0] "
                time=`docker inspect --format='{{.State.StartedAt}}' ${containers_split[0]}`
                time=`echo "$(date +%s) -$(date +%s -d "$time")" | bc`
                runtime[${containers_split[0]}]=$time

            done
            for i in ${networks[@]}; do
                IFS=" " read -a IDs <<< "${networks[$i]}"
                count=$(wc -w <<< "${networks[$i]}")
                counter=0
                for j in ${IDs[@]}; do
                    if [ "${runtime[$j]}" -gt "$specified_threshold" ]; then
                        ((counter++)) 
                    fi
                done
                if [ "$counter" -eq "$count"]; then
                    for j in ${IDs[@]}; do
                        docker stop $j 2>/dev/null
                        echo "container: '$(docker inspect --format "{{.Name}}")' stopped" >> $log_file
                    done
                fi
            done    
        done <<< "$inp"
        sleep 5
    done
}

case $1 in
    "start")
        start_daemon
        ;;
    "stop")
        stop_daemon
        ;;
    "*")
        echo "usage: daemon [start/stop]"
        ;;
esac
    