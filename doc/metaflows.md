# Metaflows

## About Metaflows

Metaflows execute functionality on an in-progress call. They can be set up in an account to 
passively listen for DTMF triggers from calls, or can be triggered actively on specific ongoing 
calls through the [Channels API](channels.md).

Konami Pro provides some common call actions directly, and can also use any 
[callflow object](https://docs.2600hz.com/kazoo/callflow/).

#### Schema

Actions applied to a call outside of the normal callflow, initiated by the caller(s)



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`binding_digit` | What DTMF will trigger the collection and analysis of the subsequent DTMF sequence | `string('1' \| '2' \| '3' \| '4' \| '5' \| '6' \| '7' \| '8' \| '9' \| '0' \| '*' \| '#')` | `*` | `false` |  
`digit_timeout` | How long to wait between DTMF presses before processing the collected sequence (milliseconds) | `integer(0..)` |   | `false` |  
`listen_on` | Which leg(s) of the call to listen for DTMF | `string('both' \| 'self' \| 'peer')` |   | `false` |  
`numbers./^[0-9]+$/` | A metaflow node defines a module to execute, data to provide to that module, and one or more children to branch to | [#/definitions/metaflow](#metaflow) |   | `false` |  
`numbers` | A list of static numbers with their flows | `object()` |   | `false` |  
`patterns./.+/` | A metaflow node defines a module to execute, data to provide to that module, and one or more children to branch to | [#/definitions/metaflow](#metaflow) |   | `false` |  
`patterns` | A list of patterns with their flows | `object()` |   | `false` |  

### metaflow

A metaflow node defines a module to execute, data to provide to that module, and one or more children to branch to


Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`children./.+/` | A metaflow node defines a module to execute, data to provide to that module, and one or more children to branch to | [#/definitions/metaflow](#metaflow) |   | `false` |  
`children` | Children metaflows | `object()` |   | `false` |  
`data` | The data/arguments of the metaflow module | `object()` | `{}` | `false` |  
`module` | The name of the metaflow module to execute at this node | `string(1..64)` |   | `true` |  



## Fetch Account-Level Metaflows

These are available to all users and devices within the account

> GET /v2/accounts/{ACCOUNT_ID}/metaflows

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/metaflows
```

### No Metaflows Assigned

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": {},
    "node": "{NODE_HASH}",
    "request_id": "{REQUEST_ID}",
    "status": "success",
    "timestamp": "{TIMESTAMP}",
    "version": "4.2.42"
}
```

## Set Metaflows on the Account

> POST /v2/accounts/{ACCOUNT_ID}/metaflows

```shell
curl -v -X POST \
    -H "X-Auth-Token: $AUTH_TOKEN" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/metaflows \
    -d '{"data":{"binding_digit":"*", "patterns":{"2(\\d+)":{"module":"transfer", "data":{"takeback_dtmf":"*1"}}}}}'
```
```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": {
        "binding_digit": "*",
        "patterns": {
            "2(\\d+)": {
                "data": {
                    "captures": [
                        "no_match"
                    ],
                    "takeback_dtmf": "*1",
                    "transfer_type": "blind"
                },
                "module": "transfer"
            }
        }
    },
    "node": "{NODE_HASH}",
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success",
    "timestamp": "{TIMESTAMP}",
    "version": "4.2.42"
}
```

In the above example, the `binding_digit` is `*` which, when pressed on the phone's keypad, tells Kazoo that a metaflow is starting. `2(\\d+)` tells Kazoo to look for a 2 and then capture one or more digits.

Thus `*21234` would instruct Kazoo to blind-transfer the caller to extension `1234`.

## Remove Metaflows from the Account

> DELETE /v2/accounts/{ACCOUNT_ID}/metaflows

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/metaflows
```
```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": {},
    "node": "{NODE_HASH}",
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success",
    "timestamp": "{TIMESTAMP}",
    "version": "4.2.42"
}
```

## Users and Devices

If you want to assign metaflows to a particular user or device, the API commands are the same except you need to include the user or device in the URI:

- Account: `/v2/accounts/{ACCOUNT_ID}/metaflows`
- User: `/v2/accounts/{ACCOUNT_ID}/users/{USER_ID}/metaflows`
- Device: `/v2/accounts/{ACCOUNT_ID}/devices/{DEVICE_ID}/metaflows`
