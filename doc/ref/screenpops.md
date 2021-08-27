# Screenpops

## About Screenpops

#### Schema



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`custom_parameters.custom_url` | Stores the dynamic link URL | `string()` |   | `false` |  
`custom_parameters.link_text` | Stores the value of the custom text for the custom_url | `string()` |   | `false` |  
`custom_parameters.name` | Contains the name that can be used to identify the caller | `string()` |   | `false` |  
`custom_parameters.render_name_as_label` | Stores whether the name will be shown in the screenpop | `boolean()` |   | `false` |  
`custom_parameters.request_method` | Stores the HTTP method of the external source parameters | `string()` |   | `false` |  
`custom_parameters.token` | Represents a dynamic value that can will be replaced by either a system data or a custom source | `string()` |   | `false` |  
`custom_parameters.type_custom_parameter` | Contains the type of information the screenpop will load (no additional data, System Data, Dynamic Link, External Data) | `string()` |   | `false` |  
`custom_parameters.url` | Stores the URL to fetch the external source parameters | `string()` |   | `false` |  
`custom_parameters.url_parameters` | Contains all the url custom params defined to concat to the custom url | `object()` |   | `false` |  
`custom_parameters` |   | `object()` |   | `false` |  
`post_call_extension_time` | Contains the time the screenpop will remain active when the temporal type is selected. | `number()` |   | `false` |  
`show_location_call_time` | Flag field for location and local time of customer call | `boolean()` | `false` | `false` |  
`type_screenpops` | Type of screenpops | `string()` | `notification` | `false` |  



## Fetch

> GET /v2/accounts/{ACCOUNT_ID}/screenpops

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/screenpops
```

## Create

> PUT /v2/accounts/{ACCOUNT_ID}/screenpops

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/screenpops
```

## Fetch

> GET /v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOP_ID}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOP_ID}
```

## Change

> POST /v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOP_ID}

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOP_ID}
```

## Patch

> PATCH /v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOP_ID}

```shell
curl -v -X PATCH \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOP_ID}
```

## Remove

> DELETE /v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOP_ID}

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOP_ID}
```

