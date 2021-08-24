### Screenpops

#### About Screenpops

This API is intended to serve as an information source for screenpops:

* Store data sent by users from screenpops-admin.
* Show the data in the preview of how the screenpop should look like.
* Serve the screenpop data when receiving a call.

#### Schema



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`custom_parameters.[].custom_url` | Stores the dynamic link URL | `string()` |   | `false` |  
`custom_parameters.[].link_text` | Stores the value of the custom text for the custom_url | `string()` |   | `false` |  
`custom_parameters.[].name` | Contains the name that can be used to identify the caller | `string()` |   | `false` |  
`custom_parameters.[].render_name_as_label` | Stores whether the name will be shown in the screenpop | `boolean()` |   | `false` |  
`custom_parameters.[].request_method` | Stores the HTTP method of the external source parameters | `string()` |   | `false` |  
`custom_parameters.[].token` | Represents a dynamic value that can will be replaced by either a system data or a custom source | `string()` |   | `false` |  
`custom_parameters.[].type_custom_parameter` | Contains the type of information the screenpop will load (no additional data, System Data, Dynamic Link, External Data) | `string()` |   | `false` |  
`custom_parameters.[].url` | Stores the URL to fetch the external source parameters | `string()` |   | `false` |  
`custom_parameters.[].url_parameters.[].name` | Contains the name for the url_parameters | `string()` |   | `false` |  
`custom_parameters.[].url_parameters.[].value` | Contains the value for the url_parameters | `string()` |   | `false` |  
`custom_parameters.[].url_parameters` | Contains all the url custom params defined to concat to the custom url | `array(object())` |   | `false` |  
`custom_parameters` |   | `array(object())` |   | `false` |  
`post_call_extension_time` | Contains the time the screenpop will remain active when the temporal type is selected. | `number()` |   | `false` |  
`show_location_call_time` | Flag field for location and local time of customer call | `boolean()` | `false` | `false` |  
`type_screenpops` | Type of screenpops | `string()` | `notification` | `false` |  



#### Fetch

> GET /v2/accounts/{ACCOUNT_ID}/screenpops

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/screenpops
```

```json
{
  "auth_token": "{AUTH_TOKEN}",
  "data": [
    {
      "id": "{SCREENPOP_ID}",
      "custom_parameters": [
        {
          "type_custom_parameter": "system_data",
          "name": "Caller Number",
          "render_name_as_label": false,
          "token": "<<caller_id_number>>"
        },
        {
          "type_custom_parameter": "dynamic_link",
          "name": "Salesforce",
          "render_name_as_label": true,
          "link_text": "View contact in Salesforce",
          "custom_url": "https://salesforce.example.com/accounts/master-account/contacts/kdamas"
        }
      ],
      "type_screenpops": "notification"
    },
    {
      "id": "{SCREENPOP_ID}",
      "custom_parameters": [
        {
          "type_custom_parameter": "system_data",
          "name": "Caller Number",
          "render_name_as_label": false,
          "token": "<<caller_id_number>>"
        },
        {
          "type_custom_parameter": "dynamic_link",
          "name": "Salesforce",
          "render_name_as_label": true,
          "link_text": "View contact in Salesforce",
          "custom_url": "https://salesforce.example.com/accounts/master-account/contacts/kdamas"
        },
        {
          "type_custom_parameter": "external_data",
          "name": "CRM Lookup",
          "render_name_as_label": false,
          "url": "example.com/crm_lookup",
          "request_method": "GET",
          "url_parameters": [
            {
              "name": "Name",
              "value": "<<caller_id_name>>"
            },
            {
              "name": "Custom",
              "value": "2600hz FTW!"
            }
          ]
        }
      ],
      "post_call_extension_time": 15,
      "type_screenpops": "persistent"
    }
  ],
  "revision": "{REVISION}",
  "status": "success"

}
```

#### Create

> PUT /v2/accounts/{ACCOUNT_ID}/screenpops

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/screenpops
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": {
        "type_screenpops": "persistent",
        "post_call_extension_time": 15,
        "custom_parameters": [
            {
                "type_custom_parameter": "system_data",
                "name": "Caller Number",
                "render_name_as_label": false,
                "token": "<<caller_id_number>>"
            }
        ],
        "id": "{SCREENPOP_ID}",
        "_read_only": {
            "modified": 63796784790,
            "id": "{SCREENPOP_ID}",
            "created": 63796784790
        }
    },
    "revision": "{REVISION}",
    "status": "success"
}
```



#### Fetch

> GET /v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOPS_ID}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOPS_ID}
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": {
        "type_screenpops": "persistent",
        "post_call_extension_time": 15,
        "custom_parameters": [
            {
                "type_custom_parameter": "system_data",
                "name": "Caller Number",
                "render_name_as_label": false,
                "token": "<<caller_id_number>>"
            }
        ],
        "id": "{SCREENPOP_ID}",
        "_read_only": {
            "modified": 63796787745,
            "id": "{SCREENPOP_ID}",
            "created": 63796787745
        }
    },
    "revision": "{REVISION}",
    "status": "success"
}
```

#### Patch

> PATCH /v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOPS_ID}

```shell
curl -v -X PATCH \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOPS_ID}
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": {
        "type_screenpops": "persistent",
        "post_call_extension_time": 25,
        "custom_parameters": [
            {
                "type_custom_parameter": "system_data",
                "name": "Caller Number",
                "render_name_as_label": false,
                "token": "<<caller_id_number>>"
            }
        ],
        "id": "{SCREENPOP_ID}",
        "_read_only": {
            "modified": 63796962651,
            "id": "{SCREENPOP_ID}",
            "created": 63796961940
        }
    },
    "revision": "{REVISION}",
    "status": "success"
}
```

#### Post

> POST /v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOPS_ID}

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOPS_ID}
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": {
        "type_screenpops": "persistent",
        "post_call_extension_time": 25,
        "custom_parameters": [
            {
                "type_custom_parameter": "system_data",
                "name": "Caller Number",
                "render_name_as_label": false,
                "token": "<<caller_id_number>>"
            },
            {
                "type_custom_parameter": "dynamic_link",
                "name": "Salesforce",
                "render_name_as_label": true,
                "link_text": "View contact in Salesforce",
                "custom_url": "https://salesforce.example.com/accounts/master-account/contacts/kdamas"
            }
        ],
        "id": "{SCREENPOP_ID}",
        "_read_only": {
            "modified": 63796963125,
            "id": "{SCREENPOP_ID}",
            "created": 63796961974
        }
    },
    "revision": "{REVISION}",
    "status": "success"
}
```

## Remove

> DELETE /v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOP_ID}

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/screenpops/{SCREENPOP_ID}
```
