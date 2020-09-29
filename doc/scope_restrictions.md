# Token Restrictions

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

