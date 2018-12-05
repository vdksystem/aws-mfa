#!/usr/bin/env bash
# Gets temporary credentials for MFA enabled accounts

if [ ! -t 0 ]
then
    echo "TTY required"
    return 1
fi

if [ -n "$AWS_SESSION_TOKEN" ]
then
    echo "Session token already set. Unset it first."
    return 1
fi

USER_ARN=$(aws sts get-caller-identity | jq -r .Arn)

USER_NAME=$(echo ${USER_ARN} | cut -d'/' -f2)

if [ -z "${USER_ARN}" ]
then
    echo "Cant find username"
    return 1
fi

echo "You logged in as ${USER_NAME}"

MFA_DEVICE=$(aws iam list-mfa-devices --user-name "${USER_NAME}" | jq -r .MFADevices[0].SerialNumber )
if [ -z "MFA_DEVICE" ]
then
    echo "Can't find MFA device"
    return 1
fi

echo -n "Enter your MFA code: "
read MFA_CODE

TOKEN=$(aws sts get-session-token --serial-number "${MFA_DEVICE}" --token-code ${MFA_CODE})

SecretAccessKey=$(echo "${TOKEN}" | jq -r .Credentials.SecretAccessKey)
SessionToken=$(echo "${TOKEN}" | jq -r .Credentials.SessionToken)
AccessKeyId=$(echo "${TOKEN}" | jq -r .Credentials.AccessKeyId)
Expiration=$(echo "${TOKEN}" | jq -r .Credentials.Expiration)

if [ -z "${SecretAccessKey}" ] || [ -z "${SessionToken}" ] || [ -z "${AccessKeyId}" ]
then
    echo "Unable to get credentials"
    return 1
fi

export AWS_SESSION_TOKEN=${SessionToken}
export AWS_SECRET_ACCESS_KEY=${SecretAccessKey}
export AWS_ACCESS_KEY_ID=${AccessKeyId}

echo "Credentials are valid until ${Expiration}"