#!/bin/bash
# Project 1 - CSV File Function

run () {
	ip=$(ifconfig ens33 | grep "inet" | head -1 | awk '{ print $2 }')
        ./APM1 $ip &
        ./APM2 $ip &
        ./APM3 $ip &
        ./APM4 $ip &
        ./APM5 $ip &
        ./APM6 $ip &
}

reportSysLevMet () {

        #####IOSTAT##################################
        iostatOut="$(iostat -y 5 1 | grep sda | sed 's/ /;/g');"
        #echo $iostatOut
        inputString=$iostatOut
        formatSysLevMet
        finalStrIoStat=$formatedString
        #echo $finalStrIoStat

        #####IFSTAT##################################
        ifstatOut=$(ifstat -t 5 | grep ens33 | sed 's/ /;/g')
        #echo $ifstatOut
        inputString=$ifstatOut
        formatSysLevMet
        finalStrIfStat=$formatedString
        #echo $finalStrIfStat

        #####DF######################################
        dfPerOut="$(df --total --output=source,size,used,avail,pcent | grep total | sed 's/ /;/g')"
        #echo $dfPerOut
        inputString=$dfPerOut
        formatSysLevMet
        finalStrDfPer=$formatedString
        #echo $finalStrDfPer

        #ifstatPID=$(pidof ifstat)
        #echo "PID of IFSTAT is :: $ifstatPID"
        #kill -9 $ifstatPID

        finalSysLevReport
}

formatSysLevMet () {

        arg1=$inputString
        strLength=${#arg1}

        for (( formatSysLevMetInc = 0; formatSysLevMetInc <= strLength; formatSysLevMetInc++ )); do
                #statements
                prevChar=$curChar
                curChar=${arg1:formatSysLevMetInc:1}
                if [[ formatSysLevMetInc -lt $((strLength-2)) ]]; then
                        nextChar=${arg1:formatSysLevMetInc+1:1}
                fi

                if [[ formatSysLevMetInc -eq 0 ]]; then
                        formatedString="${arg1:formatSysLevMetInc:1}"
                        prevChar=" "
                fi

                #echo "$prevChar$curChar$nextChar $i"

                if [[ formatSysLevMetInc -gt 0 ]]; then
                        if [[ $curChar != ";" ]]; then
                                formatedString="$formatedString$curChar"
                        elif [[ $prevChar != ";" ]] && [[ $nextChar == ";" ]]; then
                                formatedString="$formatedString,"
                        elif [[ $prevChar != ";" ]] && [[ $curChar == ";" ]] && [[ $nextChar != ";" ]]; then
                                formatedString="$formatedString,"
                        fi
                fi

                if [[ formatSysLevMetInc -eq strLength ]]; then
                        formatedString="${formatedString::-1}"
                fi

                #echo "-----------$formatedString"
        done

	prevChar=""
        curChar=""
        nextChar=""
        strLength=0

}

finalSysLevReport () {
        rxdata=$(echo "$finalStrIfStat" | cut -f 6 -d ',')
        txdata=$(echo "$finalStrIfStat" | cut -f 8 -d ',')
        diskwrites=$(echo "$finalStrIoStat" | cut -f 5 -d ',')
        availdiskcap=$(echo "$finalStrDfPer" | cut -f 3 -d ',')
        SysLevReport="$rxdata,$txdata,$diskwrites,$availdiskcap"
}

function cpuandmemory(){
	proc=$(ps -C $1 -o %cpu,%mem | tail -1 | awk 'OFS="," {print $1,$2}')
}

proc_csv () {
# $1 is seconds, $2 is data,  $3 is proc_name
	#echo "$1,$2"
	echo "$1,$2" >> "$3_metrics.csv"
}

sys_csv () {
# $1 is seconds, $2 is data
	echo "$1,$2" >> "system_metrics.csv"
}

trap cleanup EXIT

cleanup () {
        pkill APM1
        pkill APM2
        pkill APM3
        pkill APM4
        pkill APM5
        pkill APM6
        echo "Processes killed. Exiting..."
        exit
}

sec=0

true=true

run

while [[ $true ]]
do
	cpuandmemory APM1
	proc_csv $sec $proc APM1
	cpuandmemory APM2
        proc_csv $sec $proc APM2
	cpuandmemory APM3
        proc_csv $sec $proc APM3
	cpuandmemory APM4
        proc_csv $sec $proc APM4
	cpuandmemory APM5
        proc_csv $sec $proc APM5
	cpuandmemory APM6
        proc_csv $sec $proc APM6	
	reportSysLevMet $ip
	sys_csv $sec $SysLevReport
	((sec+=5))
        echo $sec
	#sleep 5
done
