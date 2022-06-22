# Commland

## About Commland

Currently only provides an API to get referred to a core compatible version of comm.land desktop application. This API bypasses authentication.

## Schema

## Fetch

> GET /v2/accounts/{ACCOUNT_ID}/commland/compatibility

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/commland/compatibility
```

