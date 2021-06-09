# Scope Restrictions

## About Scope Restrictions

## Schema



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

> GET /v2/accounts/{ACCOUNT_ID}/scope_restrictions/{SCOPE}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/scope_restrictions/{SCOPE}
```

## Change

> POST /v2/accounts/{ACCOUNT_ID}/scope_restrictions/{SCOPE}

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/scope_restrictions/{SCOPE}
```

## Remove

> DELETE /v2/accounts/{ACCOUNT_ID}/scope_restrictions/{SCOPE}

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/scope_restrictions/{SCOPE}
```

