@ECHO OFF
ECHO Build docker images
docker-compose up --build -d

ECHO Copy Webroot
XCOPY "./shared/webroot\*.*" "magento2" /E /S /I
docker cp magento2 sand_market_box_web:/var/www
docker exec -it sand_market_box_web chown -R magento2:magento2 /var/www/magento2
RMDIR magento2 /S /Q
TIMEOUT 5

FOR /f "delims=" %%A IN ('docker-compose port web 80') DO SET "CMD_OUTPUT=%%A"
FOR /f "tokens=1,* delims=:" %%A IN ("%CMD_OUTPUT%") DO SET "WEB_PORT=%%B"


ECHO Install Magento
START m2devbox-unison-sync.bat 
docker-compose exec --user magento2 web m2init magento:install --no-interaction --webserver-home-port=%WEB_PORT% 

FOR /F %%i in ('dir /b "./shared/sample-data\*.*"') do 
(
	ECHO Install Sample Data
	ECHO Copy Sample Data modules
	XCOPY "./shared/sample-data\*.*" "./sample-data" /E /S /I
	docker cp sample-data sand_market_box_web:/var/www
	docker exec -it sand_market_box_web chown -R magento2:magento2 /var/www/magento2-sample-data
	RMDIR sample-data /S /Q
	TIMEOUT 5

	ECHO Create symlinks For Sample Data modules, set valid permissions and upgrading database
	docker-compose exec web php -f /home/magento2/magento2-sample-data/dev/tools/build-sample-data.php -- --ce-source="/home/magento2/magento2"
	docker-compose exec web chown -R :magento2 /home/magento2/magento2-sample-data
	docker-compose exec --user magento2 web find /home/magento2/magento2-sample-data -type d -exec chmod g+ws {} \;
	docker-compose exec --user magento2 web rm -rf /home/magento2/magento2-sample-data/cache/* /home/magento2/magento2-sample-data/page_cache/* /home/magento2/magento2-sample-data/generation/*
	docker-compose exec --user magento2 web php /home/magento2/magento2/bin/magento setup:upgrade
	
	ECHO Reindexing (this can take a while)
	docker-compose exec --user magento2 web rm -rf magento2/var
	docker-compose exec --user magento2 web php /home/magento2/magento2/bin/magento indexer:reindex

	GOTO :EOF
)

PAUSE