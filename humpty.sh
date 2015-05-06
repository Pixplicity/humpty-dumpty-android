#!/bin/bash

#####
# Note about extracting files using `cat`:
# On some devices (e.g. Moto X 2014) this outputs newline characters. We remove these using `sed`.
#####

function notice {
    echo -e "\033[1m$1\033[0m"
}

function success {
    echo -e "\033[1;32m$1\033[0m"
}

function error {
    echo -e "\033[1;31m$1\033[0m"
}

function fatal {
    error "$1"
    echo ""
    exit
}

notice "`basename $0` v1.2.0"
echo ""

function dump_db {
    pkg=$1
    filename=$2
    notice "Dumping $pkg/$filename to dumps/$pkg/$filename..."
    adb shell run-as $pkg chmod 777 /data/data/$pkg/$filename 1>/dev/null
    adb shell run-as $pkg ls /data/data/$pkg/$filename | grep "No such file" 2>/dev/null
    if [ $? != 0 ]; then
        mkdir -p dumps/$pkg 2>/dev/null
        adb pull /data/data/$pkg/$filename dumps/$pkg/$filename 2>/dev/null
        if [ $? == 0 ]; then
            success "Success!"
        else
            adb shell run-as $pkg cat /data/data/$pkg/$filename | sed 's/\r$//' > dumps/$pkg/$filename
            if [ $? == 0 ]; then
                success "Success!"
            else
                error "Failed; found database, but could not pull it"
            fi
        fi
    else
        error "Failed; not installed?"
        list_files
    fi
    echo ""
}

function list_files {
    pkg=$1
    echo "Listing of /data/data/$pkg/:"
    #adb shell run-as $pkg chmod 777 /data/data/$pkg
    adb shell run-as $pkg ls -R /data/data/$pkg | sed 's/^/    /'
    echo ""
}

# Stop on any errors
#set -e

sel_list_apps=()
sel_dump_apps=()
sel_dump_files=()
while test $# -gt 0; do
    case "$1" in
        --help|-h|-\?)
            break
            ;;
        --list-files|-l)
            shift
            sel_list_apps+=("$1")
            ;;
        --dump|-d)
            shift
            sel_dump_apps+=("$1")
            shift
            if [ -z $1 ] || [[ $1 == -* ]]; then
                fatal "No db-file specified as -d argument"
            else
                sel_dump_files+=("$1")
            fi
            ;;
    esac
    shift
done

args=0

if [ ${#sel_list_apps[@]} -ne 0 ]; then
    args=$(($args+1))
    if $list_files; then
        for sel in ${sel_list_apps[@]}; do
            list_files $sel
        done
    fi
fi

if [ ${#sel_dump_apps[@]} -ne 0 ]; then
    args=$(($args+1))
    mkdir dumps 2>/dev/null
    for i in "${!sel_dump_files[@]}"; do
        pkg=${sel_dump_apps[$i]}
        file=${sel_dump_files[$i]}
        dump_db $pkg $file
    done
fi

if [ $args -eq 0 ]; then
    echo "Usage: `basename $0` [OPTION] HOST"
    echo "Where OPTION is any of:"
    echo "    -l, --list-files <package-name>"
    echo "        list all files inside the data directory of <package-name>"
    echo "    -d, --dump <package-name> <file>"
    echo "        dump <file> from inside data directory of <package-name>"
    exit 1
fi
