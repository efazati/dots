#!/bin/bash

URL="https://www.bon-bast.com/" 
currency_rates=$(curl -s "$URL" | xmllint --html --xpath 'string(//*[@id="usd1"])' - 2>/dev/null)

# Get Bitcoin price
bitcoin_price=$(curl -s 'https://api.coindesk.com/v1/bpi/currentprice/USD.json' | jq -r '"BTC:\(.bpi.USD.rate | gsub(",";""))"')

# Print results
echo "\$$currency_rates | $bitcoin_price"
