# dbdump

A simple database dump utility for Android.

Note that this currently only works for debuggable applications.

Usage:

    dbdump.sh [--list-files <package-name>] [--dump <package-name> <db-file>] [...]

For example, to query all database files of an application:

    $ dbdump.sh -l com.pixplicity.example
    
    Listing of /data/data/com.pixplicity.example/databases/:
    example.db
    example.db-journal

To dump that database:

    $ dbdump.sh -d com.pixplicity.example example.db
    
    Dumping com.pixplicity.example/example.db...
    Success!

All database dumps are located in the subdirectory `dbdumps`.
