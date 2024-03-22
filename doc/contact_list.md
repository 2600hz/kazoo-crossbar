### Contact List

Contact List represents the basic contact information including name and number (internal and external).

#### About Contact List

This contains the contact information of Featurecodes configured for `call_forward`, `hotdesk`, `park` etc. and Numbers and Extensions configured in `menu`, `conference`, `directory` etc. in Kazoo system.

Please note that if `Hide from Contact List` is enabled for a number/extension, it will be excluded from the Contact List.

#### Fetch

> GET /v2/accounts/{ACCOUNT_ID}/contact_list

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/contact_list
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": [
        {
            "external_number": "+14157775555",
            "internal_number": "1000",
            "name": "John Quux"
        }
    ],
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```
