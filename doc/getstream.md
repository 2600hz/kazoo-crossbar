# Getstream

## About Getstream

Integration with getstream.io

## Schema

## Create

> PUT /v2/accounts/{ACCOUNT_ID}/getstream/connect

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/getstream/connect
```

```json
{
  "auth_token": "{AUTH_TOKEN}",
  "data": {
    "id": "{TOKEN_ID}",
    "token": "{TOKEN}",
    "api_key": "{API_KEY}"
  },
  "request_id": "{REQUEST_ID}",
  "revision": "{REVISION}",
  "status": "success"
}
```

### Prerequisites on getstream API

You just need to create a doc in `system_config` with the following id : `crossbar.getstream`

The structure required is :
```json
{
  "_id": "crossbar.getstream",
  "default": {
  "secret": "{SECRET}",
  "api_key": "{API_kEY}"
  }
}
```

`{SECRET}` and `{API_KEY}` will be provided by gestream or you can go on the user's overview in getstream to check these values.
