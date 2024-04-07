#/bin/sh

if [ -f .env ]; then
    source ./.env
fi

# Function to format JSON response
format_json() {
    if command -v jq >/dev/null 2>&1; then
        echo "$1" | jq -r '.message'
    else
        echo "jq command not found. Install jq to format JSON responses."
        echo "Response:"
        echo "$1"
    fi
}

if ! which jq &>/dev/null; then
    echo "Error: 'jq' command not found. Please install jq."
else
    echo "Obtaining current IP..."
    echo ""
    IPs=$(curl -s --request GET \
        --url "https://api.controld.com/access?device_id=$RESOLVER_DEFAULT" \
        --header 'accept: application/json' \
        --header "authorization: Bearer $TOKEN_READ" | jq -r '.body.ips[].ip')
    echo ""

    echo "Adding $IPs to 3 devices..."
    echo ""
    response_code=$(curl -s -w "%{http_code}" \
        --request POST \
        --url https://api.controld.com/access \
        --header 'accept: application/json' \
        --header "authorization: Bearer $TOKEN_WRITE" \
        --header 'content-type: application/x-www-form-urlencoded' \
        --data "device_id=$RESOLVER_DEFAULT" \
        --data-urlencode "ips%5B%5D=$IPs")
    echo "Response: $response_code"
    response_code=$(curl -s -w "%{http_code}" \
        --request POST \
        --url https://api.controld.com/access \
        --header 'accept: application/json' \
        --header "authorization: Bearer $TOKEN_WRITE" \
        --header 'content-type: application/x-www-form-urlencoded' \
        --data "device_id=$RESOLVER_FAMILY" \
        --data-urlencode "ips%5B%5D=$IPs")
    echo "Response: $response_code"
    response_code=$(curl -s -w "%{http_code}" \
        --request POST \
        --url https://api.controld.com/access \
        --header 'accept: application/json' \
        --header "authorization: Bearer $TOKEN_WRITE" \
        --header 'content-type: application/x-www-form-urlencoded' \
        --data "device_id=$RESOLVER_PERSONAL" \
        --data-urlencode "ips%5B%5D=$IPs")
    echo "Response: $response_code"

    # Enable Learning IPs (Default)
    echo ""
    echo "Enabling learning IPs for 3 devices..."
    echo ""
    response_default=$(curl --request PUT \
        --url https://api.controld.com/devices/$RESOLVER_DEFAULT \
        --header 'accept: application/json' \
        --header "authorization: Bearer $TOKEN_WRITE" \
        --header 'content-type: application/x-www-form-urlencoded' \
        --data learn_ip=1)
    format_json "$response_default"
    echo ""
    response_family=$(curl --request PUT \
        --url https://api.controld.com/devices/$RESOLVER_FAMILY \
        --header 'accept: application/json' \
        --header "authorization: Bearer $TOKEN_WRITE" \
        --header 'content-type: application/x-www-form-urlencoded' \
        --data learn_ip=1)
    format_json "$response_family"
    echo ""
    response_personal=$(curl --request PUT \
        --url https://api.controld.com/devices/$RESOLVER_PERSONAL \
        --header 'accept: application/json' \
        --header "authorization: Bearer $TOKEN_WRITE" \
        --header 'content-type: application/x-www-form-urlencoded' \
        --data learn_ip=1)
    format_json "$response_personal"
    echo ""
fi
