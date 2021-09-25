#!/bin/bash

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
	rxdata=$(echo "$finalStrIfStat" | cut -f 5 -d ',')
	txdata=$(echo "$finalStrIfStat" | cut -f 7 -d ',')
	diskwrites=$(echo "$finalStrIoStat" | cut -f 5 -d ',')
	availdiskcap=$(echo "$finalStrDfPer" | cut -f 3 -d ',')
	SysLevReport="$rxdata,$txdata,$diskwrites,$availdiskcap"
}

timerExit=25
sleepVar=5

while [[ $j -lt $timerExit ]]; do
	#statements
	reportSysLevMet
	echo $SysLevReport
	#sleep $sleepVar
	j=$((j + 5))
done
