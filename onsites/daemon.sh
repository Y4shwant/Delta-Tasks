#!/bin/bash
log_file="daemon.log"
specified_threshold=5
start_daemon(){
    daemon &>/dev/null &
    PID=$!
    echo "$PID" > /tmp/daemondelete.log 
    echo "daemon started successfully"   
}
stop_daemon(){
    kill  $(cat '/tmp/daemondelete.log') 2>/dev/null
    echo "daemon stopped successfully"
}



daemon(){

    
    while true; do
        declare -A runtime
        declare -A networks
        mapfile -t containers <<< "$(docker ps --format '{{.ID}}+{{.Networks}}')"
        for i in ${containers[@]}; do
            echo "$i"
            IFS="+" read -a containers_split <<< "$i"
            networks[${containers_split[1]}]="${networks[${containers_split[1]}]} ${containers_split[0]}"
            time=`docker inspect --format='{{.State.StartedAt}}' ${containers_split[0]}`
            time=`echo "$(date +%s) -$(date +%s -d "$time")" | bc`
            runtime[${containers_split[0]}]=$time

        done
        for i in ${!networks[@]}; do
            if [ "$i" == "bridge" ];then
                continue
            fi
            IFS=" " read -a IDs <<< "${networks[$i]}"
            echo "${IDs[@]}"
            count=$(wc -w <<< "${networks[$i]}")
            counter=0
            for j in ${IDs[@]}; do
                if [ "${runtime[$j]}" -gt "$specified_threshold" ]; then
                    ((counter++)) 
                fi
            done
            if [ "$counter" -eq "$count" ]; then
                for j in ${IDs[@]}; do
                    docker stop $j 2>/dev/null
                    echo "container: '$(docker inspect --format "{{.Name}}" $j)' stopped at $(date)" >> $log_file
                done
            fi
        done    
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
    *)
        echo "usage: daemon [start/stop]"
        ;;
esac
    