@ECHO OFF
ECHO Copy Webroot
XCOPY ./shared/webroot\*.* magento2 /E /S /I
docker cp sand_market_box_web:/var/www
docker exec -it sand_market_box_web chown -R magento2:magento2 /var/www/magento2
RMDIR magento2 /S /Q
TIMEOUT 5
FOR /f "delims=" %%A IN ('docker-compose port web 80') DO SET "CMD_OUTPUT=%%A"
FOR /f "tokens=1,* delims=:" %%A IN ("%CMD_OUTPUT%") DO SET "WEB_PORT=%%B"

ECHO Install Magento
START m2devbox-unison-sync.bat 
docker-compose exec --user magento2 web m2init magento:reset --no-interaction --webserver-home-port=%WEB_PORT%
PAUSE