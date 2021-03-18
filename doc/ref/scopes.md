# Scopes

## About Scopes

#### Schema

Kazoo Auth Scope Definition



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`allow_api_request` | Indicates this scope can be requested from API | `boolean()` |   | `true` |  
`description` | Scope description | `string()` |   | `false` |  
`scopes.[]` |   | `string()` |   | `false` |  
`scopes` | List of available subscopes | `array(string())` | `[]` | `false` |  



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

