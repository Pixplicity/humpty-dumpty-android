# Humpty Dumpty - A file dumper for Android

A simple file dump utility for Android.

Note that this only works for debuggable applications.

Usage:

    humpty.sh [--list-files <package-name>] [--dump <package-name> <db-file>] [...]

For example, to query all files of an application:

    $ humpty.sh -l com.pixplicity.example
    
    Listing of /data/data/com.pixplicity.example/:
    
        /data/data/com.pixplicity.example:
        cache
        databases
        
        /data/data/com.pixplicity.example/cache:
        com.android.opengl.shaders_cache
        
        /data/data/com.pixplicity.example/databases:
        example.db
        example.db-journal

To dump the database `example.db`:

    $ humpty.sh -d com.pixplicity.example databases/example.db
    
    Dumping com.pixplicity.example/databases/example.db to dumps/com.pixplicity.example/databases/example.db...
    Success!

All database dumps are located in the subdirectory `dumps`.
