#!/bin/sh

##
#Shadowsocks Proxy Create Script
#@Version 0.0.1
#@Author wangyc
#@Email yccccc@live.com
#@Github https://github.com/wangyc/shadowsocks-creator
#@License The MIT License <https://raw.githubusercontent.com/wangyc/ss-create/master/LICENSE>
#Feel free to touch the world :)
#END

##
#Configure your smtp service HERE!
SS_MAIL_HOST="<your smtp server address>"
SS_MAIL_USER="<your smtp server user>"
SS_MAIL_PASS="<your smtp server auth code>"
SS_MAIL_SUBJECT="Nice to meet you!"
#END

##
#Modify this to enable/disable email function
EMAIL_FLAG=true
#END

##
#Modify this to enable/disable log function
#Log will save at LOG_FILE
LOG_FLAG=true
LOG_FILE="$HOME/.ss.log"
#END

##
#Script info
SCRIPT_VERSION="v0.0.1"
SCRIPT_UPDATE_DATE="2019-10-06"
SCRIPT_DESC="The day Mr. Robot final season Return."
#END

##
#Script setting
DOCKER_API_VERSION="v1.40"
DOCKER_INSTALL_SCRIPT_URL="https://get.docker.com"
SHADOWSOCKS_IMAGE="mritd/shadowsocks"
#END

PACKAGE_PATH=`dirname $0`
SS_IP=$(ifconfig | grep inet | grep -v inet6 | grep -v 127. | grep -v 172. | awk '{ print $2 }')

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

#check_docker automatically downloads the Docker installation script and terminates the script when an error occurs. 
check_docker() {
	if ! command_exists docker && ! [ -e /var/run/docker.sock ]; then
		echo
		echo
		read -p "This script requires Docker installed on your computer, install Docker?[Y/N]" yn
		while true; do
			[ "$yn" = "N" -o "$yn" = "n" ] && echo "Quiting..." && exit 0
			if [ "$yn" = "Y" -o "$yn" = "y" ]; then
				wget -O "$PACKAGE_PATH/get-docker.sh" $DOCKER_INSTALL_SCRIPT_URL
				[ $? -ne 0 ] && print_error "Downloading Docker installation script failed, check your network connection!" && exit 1
				sh "$PACKAGE_PATH/get-docker.sh"
				rm "$PACKAGE_PATH/get-docker.sh"
				break
			fi
			read -p "\ninstall Docker?[Y/N]" yn
		done
	fi
	unset yn
}

print_script_info() {
	echo
	echo
	cat <<-EOF
		█▀▀ █▀▀█ █▀▀ █▀▀█ ▀▀█▀▀ █▀▀ 　 █▀▀ █▀▀ 
		█░░ █▄▄▀ █▀▀ █▄▄█ ░░█░░ █▀▀ 　 ▀▀█ ▀▀█ 
		▀▀▀ ▀░▀▀ ▀▀▀ ▀░░▀ ░░▀░░ ▀▀▀ 　 ▀▀▀ ▀▀▀ 
	EOF
	printf "\t$SCRIPT_VERSION\t$SCRIPT_UPDATE_DATE\n"
	printf "\033[0;30m$SCRIPT_DESC\033[0m\n"
	echo
}

print_success() {
	printf '\033[32m%s\033[0m\n' "$@"
}

print_info() {
	printf "\033[34m%s\033[0m\n" "$@"
}

print_warning() {
	printf "\033[33m%s\033[0m\n" "$@"
}

print_error() {
	printf '\033[31m%s\033[0m\n' "$@"
}

#ATTENTION!!!!!!!!
#Some of the indentations below are made up of spaces, converting them to tabs will disrupt the typesetting in terminal.
print_usage() {
	cat <<-EOF
		Usage: sh ss-create.sh [OPTIONS]

		Start a Shadowsocks proxy server on your computer.

		Options:
		    -E, <Email To>		Specify the email address of recipient.
		    -e, <Encryption Method>	Encryption method: rc4-md5,
		          aes-128-gcm, aes-192-gcm, aes-256-gcm,
		          aes-128-cfb, aes-192-cfb, aes-256-cfb,
		          aes-128-ctr, aes-192-ctr, aes-256-ctr,
		          camellia-128-cfb, camellia-192-cfb,
		          camellia-256-cfb, bf-cfb,
		          chacha20-ietf-poly1305,
		          xchacha20-ietf-poly1305,
		          salsa20, chacha20 and chacha20-ietf.
		          The default cipher is chacha20-ietf-poly1305.
		    -h. <Help>			Show this usage help.
		    -n, <Name>			Shadowsocks docker container name.Default random name.
		    -P, <Password>		Shadowsocks proxy password.If not specified, script provide a random password.
		    -p, <Port>			Shadowsocks proxy binding port.If not specified, script provide a random port.

	EOF
}

check_image_exists() {
	result=$(curl --unix-socket /var/run/docker.sock -X GET -o /dev/null -I -s -w %{http_code} "http:/$DOCKER_API_VERSION/images/$SHADOWSOCKS_IMAGE/json")
	if [ "$result" = "200" ]; then
		unset result
		return 0
	else
		unset result
		return 1
	fi
}

check_encryption_method_available() {
	encryption_method_list="rc4-md5,aes-128-gcm,aes-192-gcm,aes-256-gcm,aes-128-cfb,aes-192-cfb,aes-256-cfb,aes-128-ctr,aes-192-ctr,aes-256-ctr,camellia-128-cfb,camellia-192-cfb,camellia-256-cfb,bf-cfb,chacha20-ietf-poly1305,xchacha20-ietf-poly1305,salsa20,chacha20,chacha20-ietf"
	result=`echo $encryption_method_list | awk -F, "/$SS_ENCRYPTION_METHOD/" | wc -l`
	if [ $result -eq 1 ]; then
		unset result encryption_method_list
		return 0
	else
		unset result encryption_method_list
		return 1
	fi
}

check_port_available() {
	result=`lsof -i:$SS_PORT | wc -l`
	if [ $result -eq 0 ]; then
		unset result
		return 0
	else
		unset result
		return 1
	fi
}

check_name_available() {
	result=$(curl --unix-socket /var/run/docker.socks -G -o /dev/null -w %{http_code} --data-urlencode "filters={\"name\"=[\"$SS_NAME\"]}" "http:/$DOCKER_API_VERSION/containers/json")
	if [ "$result" = "200" ]; then
		unset result
		return 0
	else
		unset result
		return 1
	fi
}

#pull_image will abort script when it failed.
pull_image() {
	echo "Pulling Shadowsocks image from Dockerhub..."
	result=$(curl --unix-socket /var/run/docker.sock -X POST -s -o /dev/null -w %{http_code} --data-urlencode "tag=latest" --data-urlencode "fromImage=$SHADOWSOCKS_IMAGE" "http:/$DOCKER_API_VERSION/images/create")
	if [ "$result" = "200" ]; then
		unset result
		print_success "Sucess!"
	else
		unset result
		print_error "Pulling shadowsocks image failed, check your network connection!"
		echo
		echo "Script Aborts!!!"
		exit 1
	
	fi
}

generate_random_password() {
	echo $(openssl rand -base64 18)
}

generate_random_name() {
	echo $(date +%s%N | md5sum | head -c 10)
}

generate_random_port() {
	min=35000
	max=50000
	rand=$(cat /dev/urandom | head -n 5 | cksum | awk '{print $1}')
	echo $(($rand%($max-$min)+$min))
	unset min max rand
}

generate_import_URL() {
	basic_url=$SS_ENCRYPTION_METHOD:$SS_PASSWORD@$SS_IP:$SS_PORT	
	base64_url=`echo $basic_url | base64 -i -`
	echo "ss://$base64_url"
	unset basic_url base64_url
}

show_ss_info() {
	echo
	echo "==================================="
	echo "ip:	$SS_IP"
	echo "Port:	$SS_PORT"
	echo "Password:	$SS_PASSWORD"
	echo "Encryption Method: $SS_ENCRYPTION_METHOD"
	echo "Import URL: $(generate_import_URL)"
	echo "==================================="
	echo
}

create_ss() {
	echo "Creating shadowsocks..."
	##
	#NOTE
	#You could add cumstom shadowsocks Docker image HERE.
	if [ "$SHADOWSOCKS_IMAGE" = "mritd/shadowsocks" ]; then
		docker run -dt --rm --name $SS_NAME -p $SS_PORT:1080/tcp -p $SS_PORT:1080/udp mritd/shadowsocks -s "-s 0.0.0.0 -p 1080 -m $SS_ENCRYPTION_METHOD -k $SS_PASSWORD -u" >/dev/null
	else
		print_error "Unknown Shadowsocks image you specified! Check script variables setting."
		exit 1
	fi
	#END
	if [ $? -eq 0 ]; then print_success "Completed!"; else print_error "Failed!"; fi
	if $LOG_FLAG; then log; fi
}

email_to() {
	echo "Try to send an email..."
	show_ss_info | SS_MAIL_HOST=$SS_MAIL_HOST \
	SS_MAIL_USER=$SS_MAIL_USER \
	SS_MAIL_PASS=$SS_MAIL_PASS \
	SS_MAIL_DEST=$SS_EMAIL_DESTINATION \
	SS_MAIL_FROM=$SS_MAIL_FROM \
	SS_MAIL_SUBJECT=$SS_MAIL_SUBJECT \
	python3 $PACKAGE_PATH/mail.py >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		print_info "Email successfully send to $SS_EMAIL_DESTINATION"
	else
		print_error "Something wrong in sending email, setting information are displayed the terminal."
		show_ss_info
	fi
}

log() {
	echo "[$(TZ=UTC-8 date +"%d/%b/%Y %H:%M:%S %z")] Create $SS_NAME with -Port: $SS_PORT -Password: $SS_PASSWORD -Method: $SS_ENCRYPTION_METHOD @@Import URL: $(generate_import_URL)" >> $LOG_FILE
}

main() {
	check_docker

	check_image_exists || (print_warning "There is no shadowsocks image on your Docker, trying to pull one..." && pull_image)

	if [ -z $SS_ENCRYPTION_METHOD ]; then
		print_warning "Use default encryption method chacha20-ietf-poly1305."
		SS_ENCRYPTION_METHOD="chacha20-ietf-poly1305"
	fi

	if [ -z $SS_PASSWORD ]; then
		print_warning "No password specified, use random password."
		SS_PASSWORD=`generate_random_password`
	fi

	if [ -z $SS_PORT ]; then
		print_warning "No port specified, use random port."
		while true; do
			SS_PORT=`generate_random_port`
			if check_port_available; then
				break
			fi
		done
	fi

	if [ -z $SS_NAME ]; then
		SS_NAME=`generate_random_name`
	else
		check_name_available || (print_warning "Shadowsocks name unavailable, use random name..." && SS_NAME=`generate_random_name`)
	fi

	create_ss

	if [ -z $SS_EMAIL_DESTINATION ]; then
		print_warning "You have not specified an email address yet, so we are not able to send you an email. The configuration information of shadowsocks are displayed on the terminal."
		show_ss_info
	elif $EMAIL_FLAG; then
		email_to
	fi
}

print_script_info

#Parsing options
while getopts "E:e:hn:P:p:" arg
do
	case $arg in
		E)
			SS_EMAIL_DESTINATION=$OPTARG
			;;
		e)
			SS_ENCRYPTTION_METHOD=$OPTARG
			if ! check_encryption_method_available; then
				print_error "The encryption method you specified is unknown!"
				print_info "Use -h option for more information."
				exit 1
			fi	
			;;
		h)
			print_usage
			exit 0
			;;
		n)
			SS_NAME=$OPTARG
			;;
		P)
			SS_PASSWORD=$OPTARG
			;;
		p)
			SS_PORT=$OPTARG
			;;
		?)
			echo
			print_usage
			exit 1
			;;
	esac
done

main