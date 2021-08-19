### Screenpops

#### About Screenpops
```
This API is intended to serve as an information source for screenpops:			
* Store data sent by users from screenpops-admin.			
* Show the data in the preview of how the screenpop should look like.			
* Serve the screenpop data when receiving a call.			
```
#### Schema


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