
#
#
# Authentication Token
import requests

url = "https://api.edgeiq.io/api/v1/platform/user/api_token_reset"

payload = "{\"email\":\"nick.white@edgeiq.io\",\"""\":"}"
headers = {
    'accept': "application/json",
    'content-type': "application/json"
    }

response = requests.request("POST", url, data=payload, headers=headers)

print(response.text)


#
#
# Get Temp API token
payload = "{\"email\":\"nick.white@edgeiq.io\",\"password\":\"machine2019\"}"
headers = {
    'accept': "application/json",
    'content-type': "application/json"
    }

response = requests.request("POST", url, data=payload, headers=headers)

print(response.text)
