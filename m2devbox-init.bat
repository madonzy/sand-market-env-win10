@ECHO OFF
ECHO Build docker images
docker-compose up --build -d

ECHO Setting new magento2 linux user password
docker-compose exec web passwd magento2

ECHO Copy Webroot
XCOPY "./shared/webroot\*.*" "magento2" /E /S /I
docker cp magento2 sand_market_box_web:/var/www
docker exec -it sand_market_box_web chown -R magento2:magento2 /home/magento2/magento2
RMDIR magento2 /S /Q
TIMEOUT 5

FOR /f "delims=" %%A IN ('docker-compose port web 80') DO SET "CMD_OUTPUT=%%A"
FOR /f "tokens=1,* delims=:" %%A IN ("%CMD_OUTPUT%") DO SET "WEB_PORT=%%B"


ECHO Install Magento
START m2devbox-unison-sync.bat 
docker-compose exec --user magento2 web m2init magento:install --no-interaction --webserver-home-port=%WEB_PORT% 

PAUSE