#!/bin/bash

#####
# Note about extracting databases using cat:
# On some devices (e.g. Moto X 2014) the database file contains some misplaced 0x0D characters. At first look these
# occur preceding a "CREATE TABLE" instruction.
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

notice "dbdump v1.1.1"
echo ""

function dump_db {
    pkg=$1
    filename=$2
    notice "Dumping $pkg/$filename to dbdumps/$pkg/$filename..."
    adb shell run-as $pkg chmod 777 /data/data/$pkg/databases/$filename 1>/dev/null
    adb shell run-as $pkg ls /data/data/$pkg/databases/$filename | grep "No such file" 2>/dev/null
    if [ $? != 0 ]; then
        mkdir dbdumps/$pkg 2>/dev/null
        adb pull /data/data/$pkg/databases/$filename dbdumps/$pkg/$filename 2>/dev/null
        if [ $? == 0 ]; then
            success "Success!"
        else
            adb shell run-as $pkg cat /data/data/$pkg/databases/$filename | sed 's/\r$//' > dbdumps/$pkg/$filename
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
    echo "Listing of /data/data/$pkg/databases/:"
    adb shell run-as $pkg chmod 777 /data/data/$pkg/databases/
    adb shell run-as $pkg ls /data/data/$pkg/databases/
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
            echo "Usage:"
            echo "dbdump.sh [--list-files <package-name>] [--dump <package-name> <db-file>] [...]"
            echo ""
            exit
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

if [ ${#sel_list_apps[@]} -ne 0 ]; then
    if $list_files; then
        for sel in ${sel_list_apps[@]}; do
            list_files $sel
        done
    fi
fi

if [ ${#sel_dump_apps[@]} -ne 0 ]; then
    mkdir dbdumps 2>/dev/null
    for i in "${!sel_dump_files[@]}"; do
        pkg=${sel_dump_apps[$i]}
        file=${sel_dump_files[$i]}
        dump_db $pkg $file
    done
fi
