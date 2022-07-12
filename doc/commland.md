# Commland

## About Commland

Provides an API that referrs the request to a core compatible version of comm.land desktop application. This API bypasses authentication as it is invoked prior to a client login.

## Schema

## Fetch

> GET /v2/accounts/{ACCOUNT_ID}/commland/compatibility

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/commland/compatibility
```

