# Allotments

## About Allotments

#### Schema

Create buckets of minutes per time-period



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`^\w+$.amount` | Time in seconds, which can be consumed | `integer(0..)` |   | `false` |  
`^\w+$.cycle` | On the basis to reset consumed allotments counter | `string('minutely' \| 'hourly' \| 'daily' \| 'weekly' \| 'monthly')` |   | `false` |  
`^\w+$.group_consume.[]` |   | `string()` |   | `false` |  
`^\w+$.group_consume` | Other allotments which will be summed, when calculating rest of allotments time on authorization | `array(string())` |   | `false` |  
`^\w+$.increment` | Step (in seconds) of incrementing counter | `integer(1..)` |   | `false` |  
`^\w+$.minimum` | Minimum amount added to counter | `integer(0..)` |   | `false` |  
`^\w+$.no_consume_time` | If call duration is less or equal of this time (in seconds), then no allotment consumed | `integer(0..)` |   | `false` |  
`^\w+$` |   | `object()` |   | `false` |  



## Fetch

> GET /v2/accounts/{ACCOUNT_ID}/allotments

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/allotments
```

## Change

> POST /v2/accounts/{ACCOUNT_ID}/allotments

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/allotments
```

## Fetch

> GET /v2/accounts/{ACCOUNT_ID}/allotments/consumed

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/allotments/consumed
```

