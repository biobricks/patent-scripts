#!/bin/bash

# Script for downloading all 1976 to 2001 
# greenbook full text patent data from USPTO bulk download site
# in weekly zip files, most recent files first.

BASE_URL=https://bulkdata.uspto.gov/data2/patent/grant/redbook/fulltext

START_YEAR=2001
END_YEAR=1976

WAIT_BETWEEN_DOWNLOADS=5 # seconds
ERROR_LOG="error.log"
MAX_ERRORS=5 # maximum number of downloading failures before this script exits

# --------------

ERROR_COUNT=0
GET_CMD="wget --limit-rate=2m --waitretry 5 --retry-connrefused --tries=3"

for ((CUR_YEAR=$START_YEAR;CUR_YEAR>=$END_YEAR;CUR_YEAR--)); do

    echo "Starting on year $CUR_YEAR"

    YEAR_URL=${BASE_URL}/${CUR_YEAR}
    
    YEAR_GET_CMD="wget -q -O- $YEAR_URL"
    
    FILES=$($YEAR_GET_CMD | awk 'match($0, /pftaps[^"]+/) {print substr($0, RSTART, RLENGTH)}')
    
    for FILENAME in $FILES; do
        WEEK_URL=${YEAR_URL}/$FILENAME
        echo "Getting $FILENAME"
        $GET_CMD $WEEK_URL
        if [ "$?" -ne "0" ]; then
            echo "Failed to get $WEEK_URL" 2>> $ERROR_LOG
            ERROR_COUNT=$((ERROR_COUNT + 1))
            if [ "$ERROR_COUNT" -gte "$MAX_ERRORS" ]; then
                echo "Got more than $MAX_ERRORS errors, so exiting. See $ERROR_LOG for details."
                exit 1
            fi
        fi
        sleep $WAIT_BETWEEN_DOWNLOADS
    done
done
