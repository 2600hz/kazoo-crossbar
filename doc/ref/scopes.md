# Scopes

## About Scopes

#### Schema

Kazoo Auth Scope Definition



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`description` | Scope description | `string()` |   | `false` |  
`id` | Id of scope | `string()` |   | `true` |  
`name` | Name of scope | `string()` |   | `false` |  
`permissions.[]` |   | `string()` |   | `true` |  
`permissions` | Specifies who can request using this scope, values are '{ACCOUNT_TYPE}:{USER_TYPE_OR_STAR}. ACCOUNT_TYPE can be 'master', 'reseller', 'non-reseller'. USER_TYPE can be 'user', 'admin' or '*' as catch all | `array(string())` |   | `true` |  
`scopes.[]` |   | `string()` |   | `false` |  
`scopes` | List of subscopes | `array(string())` | `[]` | `false` |  



## Fetch

> GET /v2/scopes

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/scopes
```

## Create

> PUT /v2/scopes

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/scopes
```

## Fetch

> GET /v2/scopes/{SCOPE}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/scopes/{SCOPE}
```

## Change

> POST /v2/scopes/{SCOPE}

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/scopes/{SCOPE}
```

## Remove

> DELETE /v2/scopes/{SCOPE}

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/scopes/{SCOPE}
```

