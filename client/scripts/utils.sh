#!/bin/bash
#check if non null input is entered and is integer
notnull_int() {
	local inputmsg=$1
	local errmsg=$2
	local result=$3
	while true; do
		echo -e $inputmsg
		read -e var
		if [[ ! -z $var ]]; then
	        if ! [[ "$var" =~ ^[0-9]+$ ]]; then
	        	echo $errormsg
	        else
	        	break
	        fi
		fi
	done
	eval $result="'$var'"
}

notnull_password() {
	local inputmsg=$1
	local result=$2
    while true; do
	    echo $inputmsg
	    read -e -s var
	    if [[ ! -z $var ]]; then
	    	break
	    fi
	done
	eval $result="'$var'"
}

notnull_string() {
	local inputmsg=$1
	local result=$2
	local tmp=$(eval "echo \"$result\" ")
	local result_val=$(eval "echo \"\$$tmp\"")
    while true; do
	    echo -e $inputmsg $result_val
	    read -e var
	    if [[ ! -z $var ]]; then
            eval $result="'$var'"
            break
	    elif [[ -z $var ]] && [[ ! -z $result_val ]]; then
            break
	    fi
	done
}

#check if non mandatory input is y/n or yes/no, sets variable value to boolean
null_yn() {
        local inputmsg=$1
        local result=$2
        echo -e $inputmsg
        read -e var
        var=${var,,}
    if [[ "$var" =~ ^(yes|y)$ ]]; then
        eval $result="true"
    else
        eval $result="false"
    fi
}

init_var() {
	local file="/test-client/data/vars.properties"
	if [ -f $file ]; then
	  while IFS='=' read -r key value; do
	    eval "${key}='${value}'"
	  done < $file
	fi
}