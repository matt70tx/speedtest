#!/bin/sh
# These values can be overwritten with env variables
LOOP="${LOOP:-false}"
LOOP_DELAY="${LOOP_DELAY:-60}"
DB_SAVE="${DB_SAVE:-false}"
DB_HOST="${DB_HOST:-http://localhost:8086}"
DB_NAME="${DB_NAME:-speedtest}"
DB_TOKEN="${DB_TOKEN:}"
DB_ORG="${DB_ORG:}"
DB_BUCKET="${DB_BUCKET:}"
DB_V2="${DB_V2:-false}"
DB_USERNAME="${DB_USERNAME:-admin}"
DB_PASSWORD="${DB_PASSWORD:-password}"

run_speedtest()
{
    DATE=$(date +%s)
    HOSTNAME=$(hostname)

    # Start speed test
    echo "Running a Speed Test..."
    JSON=$(speedtest --accept-license --accept-gdpr -f json)
    DOWNLOAD="$(echo $JSON | jq -r '.download.bandwidth')"
    UPLOAD="$(echo $JSON | jq -r '.upload.bandwidth')"
    echo "Your download speed is $(($DOWNLOAD  / 125000 )) Mbps ($DOWNLOAD Bytes/s)."
    echo "Your upload speed is $(($UPLOAD  / 125000 )) Mbps ($UPLOAD Bytes/s)."

    # Save results in the database
    if $DB_SAVE;
    then
        echo "Saving values to database..."
        if $DB_V2
        then
            save_v2
        else
            save_v1
        fi
        echo "Values saved."
    fi
}

save_v1()
{
    curl -s -S -XPOST "$DB_HOST/write?db=$DB_NAME&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" \
        --data-binary "download,host=$HOSTNAME value=$DOWNLOAD $DATE"
    curl -s -S -XPOST "$DB_HOST/write?db=$DB_NAME&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" \
        --data-binary "upload,host=$HOSTNAME value=$UPLOAD $DATE"
}

save_v2()
{
    # InfluxDB v2 use a token and not user/pass
    curl -s -S -XPOST "$DB_HOST//api/v2/write?org=$DB_ORG&bucket=$DB_BUCKET&precision=s" \
        --header "Authorization: Token $DB_TOKEN" \
        --data-binary "download,host=$HOSTNAME value=$DOWNLOAD $DATE"
    curl -s -S -XPOST "$DB_HOST//api/v2/write?org=$DB_ORG&bucket=$DB_BUCKET&precision=s" \
        --header "Authorization: Token $DB_TOKEN" \
        --data-binary "upload,host=$HOSTNAME value=$UPLOAD $DATE"
}

if $LOOP;
then
    while :
    do
        run_speedtest
        echo "Running nest test in ${LOOP_DELAY}s..."
        echo ""
        sleep $LOOP_DELAY
    done
else
    run_speedtest
fi
