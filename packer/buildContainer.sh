#!/usr/bin/env bash
##########################################################################
## Packer provisioning script for final portal container
##
## Just a first draft to test building using packer
##########################################################################
echo -e "\n=======================\n Environment: \n $(set)\n======================="

set -x

echo "Determining httpHost if not provided" && \
	if [[ "${httpHost}." == "." ]] ; then echo "No HTTP Server host passed --> using local HTTP server ..." ; httpHost=$(netstat -rn | grep '^0.0.0.0' | awk '{print $2}') ; fi && \
	thisHostIp=$(grep $(hostname) /etc/hosts | awk '{print $1}') && \
	echo "${thisHostIp} wp85.docker.container wp85" >> /etc/hosts && \
	echo -e "/etc/hosts is:\n $(cat /etc/hosts)" && \
	##
	## WP customizations - download, unpack and copy shared files
	mkdir -p /tmp/docker/buildfiles && \
	echo "Nexus url: $(getNexusUrl.sh -a shared -g at.2i.docker.buildfiles.wps.${wpsVersion} -e tar.gz -l -h ${nexusUrl} | grep GREP_FOR_ME | cut -d" " -f2-)" && \
	curl -fvL -o /tmp/docker/buildfiles/shared.tar.gz $(getNexusUrl.sh -a shared -g at.2i.docker.buildfiles.wps.${wpsVersion} -e tar.gz -l -h ${nexusUrl} | grep GREP_FOR_ME | cut -d" " -f2-) && \
	tar -C /tmp/docker/buildfiles -zxf /tmp/docker/buildfiles/shared.tar.gz && \
	rm -rf /tmp/docker/buildfiles/shared.tar.gz && \
	##
	## Copy the files to the proper location
	cp /tmp/docker/buildfiles/shared/common/bash_functions.sh /etc/docker/shared/ && \
	cp /tmp/docker/buildfiles/shared/common/getNexusUrl.sh /usr/local/bin && \
	cp /tmp/docker/buildfiles/shared/specific/startContainerWP85.sh /bin/startContainer.sh && \
	cp /tmp/docker/buildfiles/shared/specific/custom_wp85_Setup.sh ${WP_PROFILE_HOME}/customizations/custom_wp85_Setup.sh && \
	cp /tmp/docker/buildfiles/shared/specific/runWsAdmin.sh ${WP_PROFILE_HOME}/customizations/runWsAdmin.sh && \
	cp /tmp/docker/buildfiles/shared/specific/runLiquibaseDeploy.sh ${WP_PROFILE_HOME}/customizations/runLiquibaseDeploy.sh && \
	cp /tmp/docker/buildfiles/shared/specific/setHibernateDialect.sh ${WP_PROFILE_HOME}/customizations/setHibernateDialect.sh && \
	cp /tmp/docker/buildfiles/shared/specific/updateSharedAppJars.sh ${WP_PROFILE_HOME}/customizations/updateSharedAppJars.sh && \
	chmod ug+x /usr/local/bin/getNexusUrl.sh && \
	chmod +x /bin/startContainer.sh && \
	##
	## Get the portal type specific buildfiles
	curl -fvL -o /tmp/docker/buildfiles/build.tar.gz $(getNexusUrl.sh -a ${wpsType} -g at.2i.docker.buildfiles.wps.${wpsVersion} -e tar.gz -l -h ${nexusUrl} | grep GREP_FOR_ME | cut -d" " -f2-) && \
	tar -C /tmp/docker/buildfiles -zxf /tmp/docker/buildfiles/build.tar.gz && \
	rm -rf /tmp/docker/buildfiles/build.tar.gz && \
	##
	## Download customization.properties
	echo "Copying customizations.properties ..." && \
	cp /tmp/docker/buildfiles/build/customizations.properties ${WP_PROFILE_HOME}/customizations/customizations.properties && \
	##
	## Copy the MemberFixerModule.properties file if if exists
	if [[ -f /tmp/docker/buildfiles/build/MemberFixerModule.properties ]] ; then cp /tmp/docker/buildfiles/build/MemberFixerModule.properties ${WP_PROFILE_HOME}/PortalServer/wcm/shared/app/config/wcmservices/MemberFixerModule.properties ; fi && \
	##
	## Copying scripts being used
	echo "Downloading script files ..." && \
	cp /tmp/docker/buildfiles/shared/specific/custom_wp85_Setup.sh ${WP_PROFILE_HOME}/customizations/custom_wp85_Setup.sh && \
	cp /tmp/docker/buildfiles/shared/specific/runWsAdmin.sh ${WP_PROFILE_HOME}/customizations/runWsAdmin.sh && \
	cp /tmp/docker/buildfiles/shared/specific/copyOracleData.sh ${WP_PROFILE_HOME}/customizations/copyOracleData.sh && \
	cp /tmp/docker/buildfiles/shared/specific/importOracleData.sh ${WP_PROFILE_HOME}/customizations/importOracleData.sh && \
	cp /tmp/docker/buildfiles/shared/specific/setHibernateDialect.sh ${WP_PROFILE_HOME}/customizations/setHibernateDialect.sh && \
	cp /tmp/docker/buildfiles/shared/specific/updateSharedAppJars.sh ${WP_PROFILE_HOME}/customizations/updateSharedAppJars.sh && \
	cp /tmp/docker/buildfiles/shared/specific/importWcmLibs.sh ${WP_PROFILE_HOME}/customizations/importWcmLibs.sh && \
	##
	## Copy customization.properties and other files
	echo "Downloading properties and xml files ..." && \
	cp /tmp/docker/buildfiles/shared/properties/javaLogging.properties ${WP_PROFILE_HOME}/customizations/javaLogging.properties && \
	cp /tmp/docker/buildfiles/build/pumaPropertyExtensions.xml ${WP_PROFILE_HOME}/customizations/pumaPropertyExtensions.xml && \
	cp /tmp/docker/buildfiles/build/wp.base_TargetMapExclList.properties ${WP_PROFILE_HOME}/PortalServer/config/StartupPerformance/wp.base_TargetMapExclList.properties && \
	cp /tmp/docker/buildfiles/build/wp.base_TargetMapInclList.properties ${WP_PROFILE_HOME}/PortalServer/config/StartupPerformance/wp.base_TargetMapInclList.properties && \
	##
	## Binary files being used
	echo "Downloading binary files ..." && \
	curl -fvL -o ${WP_PROFILE_HOME}/customizations/cliGetXmlDataFromOracle.jar $(getNexusUrl.sh -a oracleTool -g at.2i.docker.tools -e jar -l -h ${nexusUrl} | grep GREP_FOR_ME | cut -d" " -f2-) && \
	curl -fvL -o ${WP_PROFILE_HOME}/customizations/cliPutXmlDataToDb2.jar $(getNexusUrl.sh -a db2Tool -g at.2i.docker.tools -e jar -l -h ${nexusUrl} | grep GREP_FOR_ME | cut -d" " -f2-) && \
	curl -fvL -o ${WP_PROFILE_HOME}/customizations/gbgScripts.zip $(getNexusUrl.sh -a gbgScripts -g at.2i.docker -e zip -l -h ${nexusUrl} | grep GREP_FOR_ME | cut -d" " -f2- ) && \
	curl -fvL -o ${WP_PROFILE_HOME}/customizations/jrebel.tar.gz $(getNexusUrl.sh -a jrebel -g at.2i.docker -e tar.gz -l -h ${nexusUrl} | grep GREP_FOR_ME | cut -d" " -f2- ) && \
	curl -fvL -o ${WP_PROFILE_HOME}/customizations/webdav_common_resources.zip $(getNexusUrl.sh -a ${wpsType} -g at.2i.docker.webdav_common_resources -e zip -l -h ${nexusUrl} | grep GREP_FOR_ME | cut -d" " -f2- ) && \
	##
	## AutoDeploy stuff
	echo "Copy AutoDeploy files ..." && \
	cp /tmp/docker/buildfiles/shared/specific/ad_run_deploy.sh ${WP_PROFILE_HOME}/customizations/ad_run_deploy.sh && \
	cp /tmp/docker/buildfiles/shared/specific/ad/init_deploy_app.ad ${WP_PROFILE_HOME}/customizations/ad/init_deploy_app.ad && \
	cp /tmp/docker/buildfiles/shared/specific/ad/deploy_app.ad ${WP_PROFILE_HOME}/customizations/ad/deploy_app.ad && \
	##
	## ad related configuration files
	rm -rf ${WP_PROFILE_HOME}/customizations/ad_cfg.zip && \
	echo "Zipping ad_cfg.zip: $(cd /tmp/docker/buildfiles/ad && zip -r ${WP_PROFILE_HOME}/customizations/ad_cfg.zip *)" && \
	##
	## dxsync files
	echo "Downloading dxsync files ..." && \
	curl -fvL -o ${WP_PROFILE_HOME}/customizations/dxsync-master.zip $(getNexusUrl.sh -a dxsyncmaster -g com.ibm.wps.dxsync -e zip -l -h ${nexusUrl} -r thirdparty | grep GREP_FOR_ME | cut -d" " -f2-) && \
	curl -fvL -o ${WP_PROFILE_HOME}/customizations/nvm-master.zip $(getNexusUrl.sh -a nvmmaster -g com.ibm.wps.dxsync -e zip -l -h ${nexusUrl} -r thirdparty | grep GREP_FOR_ME | cut -d" " -f2-) && \
	##
	## run setup script
	chmod +x ${WP_PROFILE_HOME}/customizations/*.sh && \
	##### export skipCleanup="-DskipCleanup=true" && \
	sh -x ${WP_PROFILE_HOME}/customizations/custom_wp85_Setup.sh -buildStep APP -nexusHost ${nexusUrl} && \
	${WP_PROFILE_HOME}/ConfigEngine/ConfigEngine.sh stop-server && \
	##
	## Backup the logs
	cd ${WP_PROFILE_HOME}/logs/ && \
	tar -jcvf WebSphere_Portal_build_logs.tar.bz2 WebSphere_Portal ffdc && \
	cd ${WP_PROFILE_HOME}/ConfigEngine/ && \
	tar -jcvf ConfigEngine_build_log.tar.bz2 log && \
	##
	## Cleanup
	rm -rf ${WP_PROFILE_HOME}/wstemp && mkdir -p ${WP_PROFILE_HOME}/wstemp && \
	rm -rf ${WP_PROFILE_HOME}/temp && mkdir -p ${WP_PROFILE_HOME}/temp && \
	rm -rf ${WP_PROFILE_HOME}/logs/WebSphere_Portal && mkdir -p ${WP_PROFILE_HOME}/logs/WebSphere_Portal && \
	rm -rf ${WP_PROFILE_HOME}/logs/ffdc && mkdir -p ${WP_PROFILE_HOME}/logs/ffdc && \
	rm -rf ${WP_PROFILE_HOME}/ConfigEngine/log && mkdir -p ${WP_PROFILE_HOME}/ConfigEngine/log && \
	${WP_PROFILE_HOME}/bin/osgiCfgInit.sh && \
	echo "===========================================" && \
	echo "Cleanup of profile temp & log directories done" && \
	echo "===========================================" && \
	##
	## Create the transfer directory for data exchange
	mkdir /transfer && \
	chmod 777 /transfer && \
	##
	## Cleanup
	rm -rf ${WP_PROFILE_HOME}/customizations/*.paa && \
	rm -rf ${WP_PROFILE_HOME}/customizations/wcm_libs_exp.tar.gz && \
	rm -rf ${WP_PROFILE_HOME}/customizations/gbgScripts.zip && \
	rm -rf ${WP_PROFILE_HOME}/customizations/was_config.tar.gz && \
	rm -rf ${WP_PROFILE_HOME}/customizations/nvm-master.zip && \
	rm -rf ${WP_PROFILE_HOME}/customizations/dxsync-master.zip && \
	rm -rf ${WP_PROFILE_HOME}/customizations/dxsync_gbgTheme_settings.tar.gz && \
	rm -rf ${WP_PROFILE_HOME}/customizations/dxsync_enhetssida_settings.tar.gz && \
	rm -rf ${WP_PROFILE_HOME}/customizations/dxsync_StyleguideTheme_settings.tar.gz && \
	rm -rf ${WP_PROFILE_HOME}/customizations/dxsync_common_resources_settings.tar.gz && \
	rm -rf ${WP_PROFILE_HOME}/customizations/webdav_common_resources.zip && \
	rm -rf ${WP_PROFILE_HOME}/customizations/webdav_enhetssida.zip && \
	rm -rf ${WP_PROFILE_HOME}/customizations/webdav_GbgTheme.zip && \
	rm -rf ${WP_PROFILE_HOME}/customizations/webdav_StyleguideTheme.zip && \
	rm -rf ${WP_PROFILE_HOME}/customizations/ad_init.ad && \
	rm -rf ${WP_PROFILE_HOME}/customizations/ad_init_deploy.ad && \
	rm -rf ${WP_PROFILE_HOME}/customizations/jrebel.tar.gz && \
	##
	## Need to preserve the build files for dbxfer & tdsSetup (if required)
	rm -rf /tmp/__tmpTar.tar && \
	cd /tmp/docker/buildfiles && tar -cvf /tmp/__tmpTar.tar dbxfer && \
	cd /tmp && rm -rf /tmp/docker && mkdir -p /tmp/docker/buildfiles && \
	cd /tmp/docker/buildfiles && tar -xf /tmp/__tmpTar.tar && rm -rf /tmp/__tmpTar.tar && \
	echo "Done ..."
