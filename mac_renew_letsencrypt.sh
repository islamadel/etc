#!/bin/sh
# Islam Adel
# 2018-11-05
# 2020-04-08
# 2020-12-11
# 2021-02-19 # delete old certificate

# mac_renew_letsencrypt.sh

## this script renews the installed lets encrypt certificate on mac
## works for renewing profile manager certificate

# requirements: certbot and an already installed letsencrypt cert
# add this script to sudo cronjob, using: sudo crontab -e
# example: 0 1 * * * /Users/admin/letsencrypt/mac_renew_letsencrypt.sh

#####

#DOMAIN_DEFAULT="mdm.domain.tld"
DOMAIN_DEFAULT="$(hostname)"
PEM_FOLDER="/etc/letsencrypt/live/${DOMAIN_DEFAULT}/" 
LOG_FOLDER="/Users/Shared/letsencrypt/logs" 
DATE=$(date +"%Y-%m-%d")
LOG_FILE="${LOG_FOLDER}/${DATE}.log" 

######

###
if [ ! -d "$LOG_FOLDER" ]; then mkdir -p "$LOG_FOLDER"; fi
###

sudo /usr/local/bin/certbot renew >> $LOG_FILE 2>&1


if cat "$LOG_FILE" | grep -q "No renewals"; then
	echo "No SSL renewals"
	exit 0
fi
 
# Generate a passphrase - UNCOMMENT THE NEXT LINE AFTER THE TEST RUN WORKED
PASS=$(openssl rand -base64 45 | tr -d /=+ | cut -c -30)
echo "${PASS}" >> "$LOG_FOLDER/priv_$DATE.pass"
# Transform the pem files into a OS X Valid p12 file - UNCOMMENT THE NEXT LINE AFTER THE TEST RUN WORKED
sudo openssl pkcs12 -export -inkey "${PEM_FOLDER}privkey.pem" -in "${PEM_FOLDER}cert.pem" -certfile "${PEM_FOLDER}fullchain.pem" -out "${PEM_FOLDER}letsencrypt_sslcert.p12" -passout pass:$PASS

# copy cert to log folder as backup
cp "${PEM_FOLDER}letsencrypt_sslcert.p12" "$LOG_FOLDER/letsencrypt_sslcert_$DATE.p12"

# import the p12 file in keychain - UNCOMMENT THE NEXT LINE AFTER THE TEST RUN WORKED
sudo security import "${PEM_FOLDER}letsencrypt_sslcert.p12" -f pkcs12 -k /Library/Keychains/System.keychain -P $PASS -A | tee -a "$LOG_FILE"

sleep 10

### DELETE INACTIVE CERTS
#reset cert counter
cert_count=0
for c in $(sudo security find-certificate -c "${DOMAIN_DEFAULT}" -Z -a /Library/Keychains/System.keychain | grep SHA-1 | awk '{print $3}'); do
	cert_hash=${c}
	cert_count=$((cert_count + 1))
	
	#Filter Let's encrypt only
	if sudo security find-certificate -a -p -c "${DOMAIN_DEFAULT}" /Library/Keychains/System.keychain | awk '/-----BEGIN CERTIFICATE-----/&&++k=='${cert_count}',/-----END CERTIFICATE-----/'  | openssl x509 -text | grep -q "Let's Encrypt"; then
		#active cert info
		active_cert_hash=$(cat "${PEM_FOLDER}cert.pem" | openssl x509 -fingerprint -noout | awk -F= '{print $2}' | tr -d :)
		active_cert_date=$(cat "${PEM_FOLDER}cert.pem" | openssl x509 -text | grep "Not After")
		
		cert_date=$(sudo security find-certificate -a -p -c "${DOMAIN_DEFAULT}" /Library/Keychains/System.keychain | awk '/-----BEGIN CERTIFICATE-----/&&++k=='${cert_count}',/-----END CERTIFICATE-----/'  | openssl x509 -text | grep "Not After") 

		if [ "${cert_hash}" != "${active_cert_hash}" ]; then
			echo "Deleting inactive certificate : ${cert_hash}" | tee -a "$LOG_FILE"
			echo "INACTIVE Certificate Date : ${cert_date}" | tee -a "$LOG_FILE"
			echo "ACTIVE Certificate Date : ${active_cert_date}" | tee -a "$LOG_FILE"
			sudo security delete-certificate -Z ${cert_hash} /Library/Keychains/System.keychain
		fi		
	fi
done
