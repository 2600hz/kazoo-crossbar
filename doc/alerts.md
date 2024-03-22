### Alerts

#### About Alerts

Kazoo enables automatic alerting for significant events and situations, ensuring users have instant insight into the status of their accounts. In general, alerts are automatically generated for provisioning errors, financials notifications (low balance, payment token, etc.), system alerts and port actions (port_requests, port_suspended, etc.).

In addition to fetch current alerts of the account, you can manually generate a new alert via API. This offers flexibility in tailoring the alerting system to specific needs or requirements.

Please note that if the config value of `enabled` under `alert` system configuration is set to `false`, alerts are not generated.

#### Schema

Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`title` | Title of the alert  | `string()` |   | `true`  |  
`message` | Alert description | `string()` |   | `true` |  
`category` | Category of the alert (Ex: `port_action_required`, `port_suspended`, `low_balance`, `no_payment_token`, `expired_payment_token`) | `string()` |   | `false` |  
`metadata.[].name` | Name of the port request | `string()` |   | `false` |  
`metadata.[].state` | Status of the port request | `string()` |   | `false` |  
`metadata.[].transition` | Transition of the port request | `array(object())` |   | `false` |  
`metadata.[].available` | Available dollars of the account | `number()` |   | `false` |  
`metadata.[].threshold` | Low balance threshold dollars | `number()` |   | `false` |  
`metadata` | Metadata of the alert | `array(object())` |   | `false` |  
`level` | Notification level of the alert | `string()` | `info`  | `false` |  
`expiration_date` | Timestamp, in Gregorian seconds, of when the alert is expiring | `integer()` |   | `false` |  
`from.[].type` | Type of the originator ('account', 'user') | `string()` |   | `true` |  
`from.[].value` | ID of the originator (AccountID or OwnerID) | `string()` |   | `true` |  
`from` | Properties related to originator of the alert | `array(object())` |   | `true` |  
`to.[].type` | Type of the recipient ('admins', 'user', 'resellers') | `string()` |   | `true` |  
`to.[].value` | ID of the recipient (AccountID or ResellerID) | `string()` |   | `true` |  
`to` | Properties related to recipient of the alert | `array(object())` |   | `true` |  

#### Fetch

> GET /v2/accounts/{ACCOUNT_ID}/alerts

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/alerts
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": [
        {
            "id": "{ALERT_ID}",
            "key": [
                "admins",
                "{ACCOUNT_ID}"
            ],
            "value": {
                "id": "{ALERT_ID}",
                "title": "kazoo telemetry grace period active",
                "message": "kazoo telemetry will automatically enable in 6 days.",
                "category": "kazoo_telemetry",
                "from": [
                    {
                        "type": "account",
                        "value": "{ACCOUNT_ID}"
                    }
                ]
            },
            "clearable": true
        }
    ],
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```

#### Create

> PUT /v2/accounts/{ACCOUNT_ID}/alerts

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{
            "data": {
                "title": "Provisioning Error",
                "message": "Error trying to provision device",
                "from": [
                    {
                        "type": "account",
                        "value": "{ACCOUNT_ID}"
                    }
                ],
                "to": [
                    {
                        "type": "admins",
                        "value": "{ACCOUNT_ID}"
                    }
                ]
            }
        }' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/alerts
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": {
        "title": "Provisioning Error",
        "message": "Error trying to provision device",
        "from": [
            {
                "type": "account",
                "value": "{ACCOUNT_ID}"
            }
        ],
        "to": [
            {
                "type": "admins",
                "value": "{ACCOUNT_ID}"
            }
        ],
        "id": "{ALERT_ID}"
    },
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```

#### Fetch

> GET /v2/accounts/{ACCOUNT_ID}/alerts/{ALERT_ID}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/alerts/{ALERT_ID}
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": {
        "title": "kazoo telemetry grace period active",
        "message": "kazoo telemetry will automatically enable in 6 days.",
        "from": [
            {
                "type": "account",
                "value": "{ACCOUNT_ID}"
            }
        ],
        "to": [
            {
                "type": "admins",
                "value": "{ACCOUNT_ID}"
            }
        ],
        "category": "kazoo_telemetry",
        "id": "{ALERT_ID}"
    },
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```

#### Remove

Clear/Remove system alerts and manually configured alerts (If `clearable` value of alert is set to `true`, you can remove the alert)

> DELETE /v2/accounts/{ACCOUNT_ID}/alerts/{ALERT_ID}

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/alerts/{ALERT_ID}
```
