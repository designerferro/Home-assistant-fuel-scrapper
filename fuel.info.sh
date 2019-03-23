#!/bin/bash
set -e
set -u
set -o pipefail

# Change this values acoording to instructions to match your Home-assistant
PROTOCOL="https"
HOST_IP_OR_NAME="yourhost"

# Your https port
PORT_NUMBER="8123"
HAPASSWORD="theverylongapikey"
SHOWFUELSHOPLOCATION="YES" \
# Set this to something else like "NO" to remove from friendly names

# Don't change anything bellow this line.
# You break it, you fix it.

usage () { 

cat <<EOF

  Options
  -------
  h - This help text
  d - Debugging for non-admin
  f - Get the fuel prices and publish them to your home-assistant

Usage:
Get fuel prices > $(basename "$0") -f "nppostocombustivel nppostocombustivel nppostocombustivel"
Debug script > $(basename "$0") -d "nppostocombustivel nppostocombustivel nppostocombustivel"

(Enter a nppostocombustivel for each Fuel shop you want to get prices from, separeted by spaces)

This utility gets the results of a search in a website so you can scrappe the values  add to your home-assistant as Sensors.
This script should be run from a server every day. find out how to added it to a sheduller like crontab.

HOW-TO GET THE nppostocombustivel
---------------------------------
First of all, lets find out the identifier for the fuel shop you want to control
1. Open Firefox or Chrome developer tools (Usually pressing F12 key).
2. Select the network tab from the development tools so you can see the requests.  
3. Go to http://www.precoscombustiveis.dgeg.pt/
4. Find the fuel shop you want info from.
5. Click on the shop so you can see the info
6. In the developer tools, on the network tab, select only the XHR traffic.
7. Click on the POST to the infoPostoCB.aspx
8. On the details for the request, read the parameters sent (Params).
9. Get the value from nppostocombustivel.

HOW-TO configure communication to your Home-assistant
-----------------------------------------------------
Now, lets configure the bellow variables for your Home-assistant and fuel shop 
--> PROTOCOL="https" <-- Accepts only "https". 
--> HOST_IP_OR_NAME="localhost" <-- Usually "localhost" worked fine, but not anymore. Enter the full address like "myserver.myhouse.dyndns.net".
--> PORT_NUMBER="8123" <-- This is the port number your Home-assistant is listening.
--> HAPASSOWRD="theverylongapikey" <-- Enter the new Long-Lived Access Tokens password you just got from your home HA profile.
EOF

exit 0
}


getFuelPrices () { 
    #DEBUG
    # echo $FUELSHOPS
    for FUELSHOP in $FUELSHOPS;
    do
    # Read local gas and diesel prices
    #DEBUG
    # echo $FUELSHOP
    curl -s "http://www.precoscombustiveis.dgeg.pt/include/infoPostoCB.aspx" \
    -H "Host:www.precoscombustiveis.dgeg.pt" \
    -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:59.0) Gecko/20100101 Firefox/59.0" \
    -H "Accept: */*" -H "Accept-Language: en-US,en;q=0.5" --compressed \
    -H "Referer: http://www.precoscombustiveis.dgeg.pt/pagina.aspx?screenwidth=1280&mlkid=gfc3xf55hmk5dz55d0vqq0mm&menucb=1" \
    -H "Content-Type: application/x-www-form-urlencoded;" \
    -H "Cookie:ASP.NET_SessionId=gfc3xf55hmk5dz55d0vqq0mm; mlkid=gfc3xf55hmk5dz55d0vqq0mm; Origem=MQ2; StartTime=MzksNDI2MjM4Nw2; Saida=SW5mb3JtYcOnw6NvIFPDrXRpbyBQcmXDp29zIENvbWJ1c3TDrXZlaXM1; ASPSESSIONIDAQSABRRD=EIBICCIDNJBNFDLPPNJGNEGA" \
    -H "DNT: 1" -H "Connection: keep-alive" \
    -H "Pragma: no-cache" \
    -H "Cache-Control: no-cache" --data "tipo=popup&nppostocombustivel=$FUELSHOP" > .data 2>&1

    < .data sed 's/||/\\\n/g' | sed 's/<[^>]*>/|/g' | sed 's/\€/EUR/g' | sed 's/||/\n/g' | sed 's/\ |//g' | sed 's/|G/G/g' | sed 's/\ EUR//g'  | sed 's/\á/a/g' | sed 's/\ó/o/g' | sed 's/\ \-\ //g' > .information

    FUELSHOPLOCATION=$(< .data sed 's/.*infoTitulo\"><h1>//g' | sed 's/<\/h1>.*//g' | sed 's/<br>.*//g')
    #DEBUG
    #echo $FUELSHOPLOCATION 
      # Clean the html out of this to get the values for each fuel price.
      for LABEL in 'Gasoleo simples' 'Gasoleo\|' 'Gasoleo especial' 'Gásoleo colorido' 'Gasolina simples 95' \
      	'Gasolina 95' 'Gasolina especial 95' 'Gasolina 98' 'Gasolina especial 98' 'GPL Auto' \
      	'GNC (gas natural comprimido) - EUR/m3' 'GNC (gas natural comprimido) - EUR/kg' \
      	'GNL (gas natural liquefeito) - EUR/kg';
      do
        SEDLABEL=$(echo "$LABEL" | sed 's/\ /\\ /g' | sed 's/\//\\\//g')
        FUELPRICE=$(awk -F"|" '/'"$SEDLABEL"'/{print $2}' .information)
        sensorType=$(echo "$LABEL" | sed 's/\ /_/g' | sed 's~[^[:alnum:]|_]\+~~g')

        if [ $SHOWFUELSHOPLOCATION = "YES" ]
        then
          FRIENDLYNAME="$LABEL ($FUELSHOPLOCATION)"
        else
          FRIENDLYNAME="$LABEL"
        fi

        SENSOR="$FUELSHOP"
        SENSOR+="_"
        SENSOR+="$sensorType"

            if ! [ -z "$FUELPRICE" ];
            then
                # DEBUG
                #echo "$LABEL $FUELPRICE"
                # Add to home-assistant
                curl -s -k -X POST -H "Authorization: Bearer $HAPASSWORD" \
                -H "Content-Type: application/json" \
                -d '{"state": "'$FUELPRICE'", "attributes": {"unit_of_measurement": "€", "icon": "mdi:gas-station", "friendly_name":"'"$FRIENDLYNAME"'"}}' \
                $PROTOCOL://$HOST_IP_OR_NAME:$PORT_NUMBER/api/states/sensor.fuel_"$SENSOR" >/dev/null 2>&1
            fi
      done
  done
  exit 0
}

debugme () { 
    #DEBUG
    # set -x
    SHOWFUELSHOPLOCATION="YES"
    bash --version > debugme.txt 
    echo "$FUELSHOPS" >> debugme.txt
    for FUELSHOP in $FUELSHOPS;
    do
    # Read local gas and diesel prices
    #DEBUG
    # echo $FUELSHOP
    curl -s "http://www.precoscombustiveis.dgeg.pt/include/infoPostoCB.aspx" \
    -H "Host:www.precoscombustiveis.dgeg.pt" \
    -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:59.0) Gecko/20100101 Firefox/59.0" \
    -H "Accept: */*" -H "Accept-Language: en-US,en;q=0.5" --compressed \
    -H "Referer: http://www.precoscombustiveis.dgeg.pt/pagina.aspx?screenwidth=1280&mlkid=gfc3xf55hmk5dz55d0vqq0mm&menucb=1" \
    -H "Content-Type: application/x-www-form-urlencoded;" \
    -H "Cookie:ASP.NET_SessionId=gfc3xf55hmk5dz55d0vqq0mm; mlkid=gfc3xf55hmk5dz55d0vqq0mm; Origem=MQ2; StartTime=MzksNDI2MjM4Nw2; Saida=SW5mb3JtYcOnw6NvIFPDrXRpbyBQcmXDp29zIENvbWJ1c3TDrXZlaXM1; ASPSESSIONIDAQSABRRD=EIBICCIDNJBNFDLPPNJGNEGA" \
    -H "DNT: 1" -H "Connection: keep-alive" \
    -H "Pragma: no-cache" \
    -H "Cache-Control: no-cache" --data "tipo=popup&nppostocombustivel=$FUELSHOP" > .data 2>&1

    cat .data >> debugme.txt 

    echo "==============" >> debugme.txt 

    < .data sed 's/||/\\\n/g' | sed 's/<[^>]*>/|/g' | sed 's/\€/EUR/g' | sed 's/||/\n/g' | sed 's/\ |//g' | sed 's/|G/G/g' | sed 's/\ EUR//g'  | sed 's/\á/a/g' | sed 's/\ó/o/g' | sed 's/\ \-\ //g' > .information

    cat .information >> debugme.txt

    echo "==============" >> debugme.txt 

    FUELSHOPLOCATION=$(< .data sed 's/.*infoTitulo\"><h1>//g' | sed 's/<\/h1>.*//g' | sed 's/<br>.*//g')
    #DEBUG
    echo "$FUELSHOPLOCATION" >> debugme.txt
      # Clean the html out of this to get the values for each fuel price.
      for LABEL in 'Gasoleo simples' 'Gasoleo\|' 'Gasoleo especial' 'Gásoleo colorido' 'Gasolina simples 95' \
        'Gasolina 95' 'Gasolina especial 95' 'Gasolina 98' 'Gasolina especial 98' 'GPL Auto' \
        'GNC (gas natural comprimido) - EUR/m3' 'GNC (gas natural comprimido) - EUR/kg' \
        'GNL (gas natural liquefeito) - EUR/kg';
      do
        SEDLABEL=$(echo "$LABEL" | sed 's/\ /\\ /g' | sed 's/\//\\\//g')
        FUELPRICE=$(awk -F"|" '/'"$SEDLABEL"'/{print $2}' .information)
        sensorType=$(echo "$LABEL" | sed 's/\ /_/g' | sed 's~[^[:alnum:]|_]\+~~g')

        if [ $SHOWFUELSHOPLOCATION = "YES" ]
        then
          FRIENDLYNAME="$LABEL ($FUELSHOPLOCATION)"
        else
          FRIENDLYNAME="$LABEL"
        fi

        SENSOR="$FUELSHOP"
        SENSOR+="_"
        SENSOR+="$sensorType"

            if ! [ -z "$FUELPRICE" ];
            then
                # DEBUG
                echo "$LABEL $FUELPRICE" >> debugme.txt
            fi
      done
  done
  exit 0
}

while getopts 'dh:f' OPTION; do
  case "$OPTION" in
    f)
      FUELSHOPS="$2"
      getFuelPrices 
      ;;
    d)
      FUELSHOPS="$2"
      debugme
      ;;
    h)
      usage
      ;;

    ?)
      usage
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"
