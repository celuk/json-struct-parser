#!/bin/bash

if [[ $1 != "-f" ]]
then
    file="$1"
else
    file="$2"
fi
lineStr=""

while read -r line
do
    if [ ! -z "$line" ]
    then
        lineStr+="$line"
    fi
done < "$file"

jescape='(\\[^[:cntrl:]u]|\\u[0-9a-fA-F]{4})'
jchar='[^[:cntrl:]"\\]'
jstring="\"${jchar}*(${jescape}${jchar}*)*\""
jnumber='-?(0|[1-9][0-9]*)([.][0-9]*)?([eE][+-]?[0-9]*)?'
jkeyword='null|false|true'
jspace='[[:space:]]+'

tokArr=()

while read -r sliceLine; do
        tokArr+=( "$sliceLine" )
done < <( echo "$lineStr" | grep -E -o -e "${jstring}|${jnumber}|${jkeyword}|${jspace}|." | grep -E -v -e "^${jspace}$" | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -d '"' )

curBraces=0

tagArr=()

dupControlArr=()

for ((i = 0 ; i < ${#tokArr[@]} ; i++))
do
    strtag=""
    if [[ ${tokArr[$i]} == "{" ]]
    then
        ((curBraces++))
    elif [[ ${tokArr[$i]} == "}" ]]
    then
        ((curBraces--))
    else
        if [[ ${tokArr[$i+1]} == "," && ${tokArr[$i]} == "]" ]]
        then
            tagArr[$curBraces - 1]=""
        fi
        

        if [[ (${tokArr[$i-1]} == "{" || ${tokArr[$i-1]} == ",") && ${tokArr[$i+1]} == ":" ]]
        then
            if [[ ${tokArr[$i+2]} == "[" ]]
            then
                tokArr[$i]="${tokArr[$i]}[]"
            fi

            for j in ${tagArr[@]}
            do
                strtag+="$j."
            done
            
            str="$.$strtag${tokArr[i]}"

            if [[ ! " ${dupControlArr[*]} " =~ " ${str} " ]]
            then
                echo $str
            fi

            dupControlArr+=($str)

            if [[ (${tokArr[$i-1]} == "{" || ${tokArr[$i-1]} == ",") && (${tokArr[$i+2]} == "{" || ${tokArr[$i+2]} == "[") ]]
            then
                tagArr[$curBraces - 1]=${tokArr[$i]}
            fi
        fi

        if [[ ${tokArr[$i-1]} == "}" && ${tokArr[$i]} == "," ]]
        then
            tagArr[$curBraces]=""
        fi
    fi
done

