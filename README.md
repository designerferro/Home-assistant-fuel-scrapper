# Home-assistant-fuel-scrapper
Fuel prices scraper for Home-assistant
--------------------------------------

This utility gets the results of a search in a website so you can scrappe the values and add them to your [Home-assistant](https://www.home-assistant.io/) as sensors. 

The values are scrapped from the portuguese national energy authority,which only has values for fuel shops in Portugal.

After scrapping the values, it writes them directly to your [Home-assistant](https://www.home-assistant.io/) through it's API. This means that you don't need to enter anything in your configuration.yaml. 

This script should be runned from a server on a dailly bases. Find out how to [add it to a scheduller like crontab](https://www.cyberciti.biz/faq/how-do-i-add-jobs-to-cron-under-linux-or-unix-oses/).

HOW-TO
------
First of all, you need to find out the identifier for the fuel shop you want to control
1. Open Firefox or Chrome developer tools (Usually pressing F12 key).
1. Select the network tab from the development tools so you can see the requests.  
1. Go to http://www.precoscombustiveis.dgeg.pt/
1. Find the fuel shop you want info from.
1. Click on the shop so you can see the info
1. In the developer tools, on the network tab, select only the XHR traffic.
1. Click on the POST to the infoPostoCB.aspx
1. On the details for the request, read the parameters sent (Params).
1. Take note of the value for nppostocombustivel.

Now, lets configure the bellow variables for your Home-assistant and fuel shop:

Home-assistant
--------------
- PROTOCOL="http" <-- Enter either "http" or "https", depending where your Home-sistant is listening 

- HOST_IP_OR_NAME="localhost" <-- Usually "localhost" is fine. If you are running is script from another computer other than the one running Home-assistant, enter ther a named address like "myserver.myhouse" or an internet protocol number (IP) ke "192.168.1.20"

- PORT_NUMBER="8123" <-- This is the port number your Home-assistant is listening.

- HAPASSOWRD="SomePassword" <-- You shouldnt leave you Home-assistant running thout a password. Enter yours here. Its the same password you entered for i_password: at configuration.yaml

Fuel shop identifier
--------------------
- FUEL_SHOP="170157" <-- In the first step you got this from the nppostocombustivel value.
