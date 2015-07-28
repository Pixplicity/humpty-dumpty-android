#!/bin/bash

# fix for OS X:
export LC_CTYPE=C 
export LANG=C

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

function dump_db {
    pkg=$1
    filename=$2
    dbfile="${filename##*/}"
    notice "Dumping $pkg/$filename to dumps/$pkg/$filename..."
    mode="$(adb shell run-as $pkg ls -al /data/data/$pkg/$filename | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf("%0o ",k)}')"
    # make the file world-readable
    adb shell run-as $pkg chmod 777 /data/data/$pkg/$filename 1>/dev/null
    ret=$?
    if [ $ret == 255 ]; then
        fatal "Failed; no device, or multiple devices attached to adb"
    elif [ $ret != 0 ]; then
        fatal "Failed; adb not found?"
    fi
    # check if the file exists
    adb shell run-as $pkg ls /data/data/$pkg/$filename | grep "No such file" 2>/dev/null
    if [ $? != 0 ]; then
        # prepare a directory
        mkdir -p `dirname dumps/$pkg/$filename` 2>/dev/null
        # attempt to pull the file
        adb pull /data/data/$pkg/$filename dumps/$pkg/$filename 2>/dev/null
        if [ $? == 0 ]; then
            success "Success!"
        else
            # couldn't pull the file; stream its contents instead, removing any end-of-line character returns
            if [ $(uname) == 'Darwin' ]; then
                adb shell run-as $pkg cat /data/data/$pkg/$filename > dumps/$pkg/$filename
                perl -pi -e 's/\r\n/\n/g' dumps/$pkg/$filename
            else
                adb shell run-as $pkg cat /data/data/$pkg/$filename | sed 's/\r$//' > dumps/$pkg/$filename
            fi
            if [ $? == 0 ]; then
                success "Success!"
            else
                # couldn't stream file contents; copy to /sdcard instead and pull from there
                adb shell mkdir -p /sdcard/humpty
                adb shell cp /data/data/$pkg/$filename /sdcard/humpty/$dbfile
                adb pull /sdcard/humpty/$dbfile dumps/$pkg/$filename 2>/dev/null
                if [ $? == 0 ]; then
                    success "Success!"
                else
                    error "Failed; found database, but could not pull it"
                fi
                echo "Cleaning up..."
                adb shell rm -r /sdcard/humpty
            fi
        fi
    else
        error "Failed; not installed?"
        list_files
    fi
    # restore permission on file
    adb shell run-as $pkg chmod $mode /data/data/$pkg/$filename 1>/dev/null
    if [ $? != 0 ]; then
        error "Could not restore file mode $mode on /data/data/$pkg/$filename"
    fi
    echo ""
}

function list_files {
    pkg=$1
    echo "Listing of /data/data/$pkg/:"
    adb shell run-as $pkg ls -R /data/data/$pkg | sed 's/^/    /'
    ret=$?
    if [ $ret == 255 ]; then
        fatal "Failed; no device, or multiple devices attached to adb"
    elif [ $ret != 0 ]; then
        fatal "Failed; adb not found?"
    fi
    echo ""
}

# Stop on any errors
#set -e

show_help=false
sel_list_apps=()
sel_dump_apps=()
sel_dump_files=()
while test $# -gt 0; do
    case "$1" in
        --help|-h|-\?)
            show_help=true
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

if [ ${#sel_list_apps[@]} -eq 0 ] && [ ${#sel_dump_apps[@]} -eq 0 ]; then
    show_help=true
fi
if [ $show_help = true ]; then
    echo "Usage: `basename $0` [OPTION] HOST"
    echo "Where OPTION is any of:"
    echo "    -l, --list-files <package-name>"
    echo "        list all files inside the data directory of <package-name>"
    echo "    -d, --dump <package-name> <file>"
    echo "        dump <file> from inside data directory of <package-name>"
    exit 1
fi

echo ""

if [ ${#sel_list_apps[@]} -ne 0 ]; then
    if $list_files; then
        for sel in ${sel_list_apps[@]}; do
            list_files $sel
        done
    fi
fi

if [ ${#sel_dump_apps[@]} -ne 0 ]; then
    mkdir dumps 2>/dev/null
    for i in "${!sel_dump_files[@]}"; do
        pkg=${sel_dump_apps[$i]}
        file=${sel_dump_files[$i]}
        dump_db $pkg $file
    done
fi
