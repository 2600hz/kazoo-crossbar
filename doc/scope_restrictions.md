# Token Restrictions

## About Token Restrictions

#### Schema

Crossbar Scope Restrictions  Definition



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`id` | Scope Restriction unique identifier | `string()` |   | `false` |  
`scopes.[]` |   | `string()` |   | `false` |  
`scopes` | List of enforced scopes | `array(string())` | `[]` | `false` |  



## Fetch

> GET /v2/accounts/{ACCOUNT_ID}/token_restrictions

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/token_restrictions
```

## Change

> POST /v2/accounts/{ACCOUNT_ID}/token_restrictions

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/token_restrictions
```

## Remove

> DELETE /v2/accounts/{ACCOUNT_ID}/token_restrictions

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/token_restrictions
```

