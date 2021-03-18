# Scope Restrictions

## About Scope Restrictions

Scope Restrictions provide a mechanism to create an alias for a scope of scopes and define a set of crossbar token restrictions.

A scope restriction is assigned by setting it in the `scope_restrictions` array on the user object.

##### Example Scope Restriction Document
This 
```json
{
  "_id": "support",
  "_rev": "15-2a48ea5cca7783dde1518f95a250a704",
  "pvt_type": "scope_restriction",
  "scopes": [
    "crossbar:read_only"
  ],
  "token_restrictions": {
    "_": [
      {
        "allowed_accounts": [
          "_"
        ],
        "rules": {
          "#": [
            "GET"
          ]
        }
      }
    ]
  }
}
```

#### Schema

Auth Scope Restrictions Definition



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`description` | Scope description | `string()` |   | `false` |  
`http.allow./^(GET|PUT|POST|PATCH|DELETE|_)$/.[]` |   | `string()` |   | `false` |  
`http.allow./^(GET|PUT|POST|PATCH|DELETE|_)$/` | URL paths | `array(string())` |   | `false` |  
`http.allow` |   | `object()` |   | `false` |  
`http.deny./^(GET|PUT|POST|PATCH|DELETE|_)$/.[]` |   | `string()` |   | `false` |  
`http.deny./^(GET|PUT|POST|PATCH|DELETE|_)$/` | URL paths | `array(string())` |   | `false` |  
`http.deny` |   | `object()` |   | `false` |  
`http` | Token Restrictions to enforce for HTTP/HTTPS transport protocol | `object()` |   | `false` |  
`precedence` | If scope restriction request matches both allow and deny rules which one should take precedence | `string('allow' | 'deny')` | `allow` | `false` |  
`scope_name` | Name of scope this restriction is applying to | `string()` |   | `true` |  



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

