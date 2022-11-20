#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: run.sh -f certificate.pfx -p password -s storage.001 -l [256|512]"
    exit 1
fi

while getopts ":f:p:s:l:" opt; do
  case $opt in
    f) fullname="$OPTARG"
    ;;
    p) password="$OPTARG"
    ;;
    s) storage="$OPTARG"
    ;;
	  l) alg="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

filename=$(basename -- "$fullname")
extension="${filename##*.}"
filename="${filename%.*}"

cd /work/

if [ -z ${password} ];
then
    echo "No password present."
    exit
else
    if [ -z ${fullname} ];
    then
        if [ -z ${storage} ];
        then
            echo "No PFX file or container folder present."
            exit
        else
            privkey2012 ${storage} ${password} > ${storage}.key.pem
        fi
    else
        openssl pkcs12 -in ${fullname} -clcerts -password pass:${password} -nokeys -out ${filename}.crt.pem
        if [ -z ${storage} ];
        then
            openssl pkcs12 -in ${fullname} -password pass:${password} -nocerts -out ${filename}.key -passout pass:${password}
            openssl pkey -engine gost -in ${filename}.key -passin pass:${password} -out ${filename}.key.pem
            rm -rf ${filename}.key
        else
            privkey2012 ${storage} ${password} > ${filename}.key.pem
        fi
		if [ ${alg} ];
		then
			openssl pkcs12 -engine gost -export -inkey ${filename}.key.pem -in ${filename}.crt.pem -out ${filename}.p12 -password pass:${password} -keypbe gost89 -certpbe gost89 -macalg md_gost12_${alg}
		fi
    fi
fi
