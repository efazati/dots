#!/bin/bash

# Get currency exchange rates - https://github.com/SamadiPour/bonbast
currency_rates=$(bonbast export | jq -r '"$:\(.USD.sell) | €:\(.EUR.sell)"')

# Get Bitcoin price
bitcoin_price=$(curl -s 'https://api.coindesk.com/v1/bpi/currentprice/USD.json' | jq -r '"BTC:\(.bpi.USD.rate | gsub(",";""))"')

# Print results
echo "$currency_rates | $bitcoin_price"
