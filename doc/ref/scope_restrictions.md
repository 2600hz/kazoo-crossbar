# Scope Restrictions

## About Scope Restrictions

#### Schema

Crossbar Scope Restrictions  Definition



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`id` | Scope Restriction unique identifier | `string()` |   | `false` |  
`scopes.[]` |   | `string()` |   | `false` |  
`scopes` | List of enforced scopes | `array(string())` | `[]` | `false` |  
`token_restrictions./^\w+$/.[].allowed_accounts.[]` |   | `string()` |   | `false` |  
`token_restrictions./^\w+$/.[].allowed_accounts` | Account allowed to match this item | `array(string())` |   | `false` |  
`token_restrictions./^\w+$/.[].rules./^[\w/#*]+$/.[]` |   | `string('GET' \| 'PUT' \| 'POST' \| 'PATCH' \| 'DELETE' \| '_')` |   | `false` |  
`token_restrictions./^\w+$/.[].rules./^[\w/#*]+$/` | verbs | `array(string('GET' \| 'PUT' \| 'POST' \| 'PATCH' \| 'DELETE' \| '_'))` |   | `false` |  
`token_restrictions./^\w+$/.[].rules` | Rules applied to endpoint parameters | `object()` |   | `false` |  
`token_restrictions./^\w+$/` |   | `array(object())` |   | `false` |  
`token_restrictions` | Token Restrictions to enforce for these scopes | `object()` |   | `false` |  



## Fetch

> GET /v2/accounts/{ACCOUNT_ID}/scope_restrictions

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/scope_restrictions
```

## Create

> PUT /v2/accounts/{ACCOUNT_ID}/scope_restrictions

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/scope_restrictions
```

## Fetch

> GET /v2/accounts/{ACCOUNT_ID}/scope_restrictions/{SCOPE_RESTRICTION}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/scope_restrictions/{SCOPE_RESTRICTION}
```

## Change

> POST /v2/accounts/{ACCOUNT_ID}/scope_restrictions/{SCOPE_RESTRICTION}

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/scope_restrictions/{SCOPE_RESTRICTION}
```

## Remove

> DELETE /v2/accounts/{ACCOUNT_ID}/scope_restrictions/{SCOPE_RESTRICTION}

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/scope_restrictions/{SCOPE_RESTRICTION}
```

