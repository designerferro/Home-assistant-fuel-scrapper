#!/bin/bash

# This utility gets the results of a search in a website so you can scrappe the values to add to your home-assistant as Sensors.
# This script should be run from a server every day. find out how to added it to a scheduller like crontab.
#
# HOW-TO
# --------
# First of all, lets find out the identifier for the fuel shop you want to control
# 1. Open Firefox or Chrome developer tools (Usually pressing F12 key).
# 2. Select the network tab from the development tools so you can see the requests.  
# 3. Go to http://www.precoscombustiveis.dgeg.pt/
# 4. Find the fuel shop you want info from.
# 5. Click on the shop so you can see the info
# 6. In the developer tools, on the network tab, select only the XHR traffic.
# 7. Click on the POST to the infoPostoCB.aspx
# 8. On the details for the request, read the parameters sent (Params).
# 9. Get the value from nppostocombustivel.
# 
# Now, lets configure the bellow variables for your Home-assistant and fuel shop 
# --> PROTOCOL="http" <-- Enter either "http" or "https", depending where your Home-Assistant is listening 
# --> HOST_IP_OR_NAME="localhost" <-- Usually "localhost" is fine. If you are running this script from another computer other than the one running Home-assistant, enter either a named address like "myserver.myhouse" or an internet protocol number (IP) like "192.168.1.20"
# --> PORT_NUMBER="8123" <-- This is the port number your Home-assistant is listening.
# --> HAPASSOWRD="SomePassword" <-- You shouldnt leave you Home-assistant running without a password. Enter yours here. Its the same password you entered for api_password: at configuration.yaml
# --> FUEL_SHOP="170157" <-- In the first step you got this from the nppostocombustivel value.

PROTOCOL="https"
HOST_IP_OR_NAME="localhost"
PORT_NUMBER="8123"
HAPASSOWRD="S0m3p455w0rd"
FUEL_SHOP="170157"


# Read local gas and diesel prices
curl -s 'http://www.precoscombustiveis.dgeg.pt/include/infoPostoCB.aspx' -H 'Host: www.precoscombustiveis.dgeg.pt' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:59.0) Gecko/20100101 Firefox/59.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Referer: http://www.precoscombustiveis.dgeg.pt/pagina.aspx?screenwidth=1280&mlkid=gfc3xf55hmk5dz55d0vqq0mm&menucb=1' -H 'Content-Type: application/x-www-form-urlencoded;' -H 'Cookie: ASP.NET_SessionId=gfc3xf55hmk5dz55d0vqq0mm; mlkid=gfc3xf55hmk5dz55d0vqq0mm; Origem=MQ2; StartTime=MzksNDI2MjM4Nw2; Saida=SW5mb3JtYcOnw6NvIFPDrXRpbyBQcmXDp29zIENvbWJ1c3TDrXZlaXM1; ASPSESSIONIDAQSABRRD=EIBICCIDNJBNFDLPPNJGNEGA' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' --data 'tipo=popup&nppostocombustivel=170157' > .data

cat .data | sed 's/||/\\\n/g' | sed 's/<[^>]*>/|/g' | sed 's/\€/EUR/g' | sed 's/||/\n/g' | sed 's/\ |//g' | sed 's/|G/G/g' | sed 's/\ EUR//g'  | sed 's/\á/a/g' | sed 's/\ó/o/g' | sed 's/\ \-\ //g' > .information

# Clean the html out of this to get the values for each fuel price.
for LABEL in 'Gasoleo simples' 'Gasoleo\|' 'Gasoleo especial' 'Gásoleo colorido' 'Gasolina simples 95' 'Gasolina 95' 'Gasolina especial 95' 'Gasolina 98' 'Gasolina especial 98' 'GPL Auto' 'GNC (gas natural comprimido) - EUR/m3' 'GNC (gas natural comprimido) - EUR/kg' 'GNL (gas natural liquefeito) - EUR/kg';
do
  SEDLABEL=$(echo $LABEL | sed 's/\ /\\ /g' | sed 's/\//\\\//g')
  FUELPRICE=$(awk -F"|" '/'"$SEDLABEL"'/{print $2}' .information)
  sensorType=$(echo "$LABEL" | sed 's/\ /_/g' | sed 's~[^[:alnum:]|_]\+~~g')

      if ! [ -z "$FUELPRICE" ];
      then
          # Debug
          # echo "$FUELPRICE"
       # Add to home-assistant
         curl -s -X POST -H "x-ha-access: $HAPASSOWRD" \
         -H "Content-Type: application/json" \
         -d '{"state": "'$FUELPRICE'", "attributes": {"unit_of_measurement": "€", "icon": "mdi:gas-station", "friendly_name":"'"$LABEL"'"}}' \
        $PROTOCOL://$HOST_IP_OR_NAME:$PORT_NUMBER/api/states/sensor.fuel_$FUEL_SHOP_$sensorType >/dev/null 2>&1
      fi
done

