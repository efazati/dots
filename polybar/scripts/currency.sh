#!/bin/bash

# Get USD price from mazaneh.net
URL="https://mazaneh.net/en/currencyprice/USD"
HEADERS=(
    -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:129.0) Gecko/20100101 Firefox/129.0'
    -H 'Accept: */*'
    -H 'Content-Type: application/x-www-form-urlencoded; charset=utf-8'
    -H 'X-Requested-With: XMLHttpRequest'
)
currency_rates=$(curl -s "$URL" "${HEADERS[@]}" -X POST --data 'ScriptManager1=Listcurrency%7CTimer1&__EVENTTARGET=Timer1' | grep -o '<h3>[0-9]*</h3>' | head -n 1 | sed 's/<h3>\(.*\)<\/h3>/\1/')

# Get Bitcoin price from Coingecko API
bitcoin_price=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd" | jq -r '"BTC:" + (.bitcoin.usd | tostring)' || echo "BTC:0")

# Print results
echo "\$$currency_rates | $bitcoin_price"
