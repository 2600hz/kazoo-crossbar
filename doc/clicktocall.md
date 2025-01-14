# Click To Call

Click-to-call allows you initiate a phone call between a contact and a destination.
A pre-determined extension will be dialed first, then dialing the contact destination
will be attempted and the two are bridged. The call appears like if the contact dialed
into the extension, and when a extension answers, dialing the contact appears like
the extension dialed the contact. You can decide which side to be dialed first.

Click-to-call, also known as Click-to-talk or Click-to-dial, is a common functionality of
a Web-based communication in which a person can clicks on a link, button or an object to
immediately connect an endpoint to the contact in the clicked object.

Click-to-call initiates the call between two endpoints: 1. The contact which can be a phone
number, extension or SIP URI. 2. An endpoint to be connected to the contact.

## Static or dynamic Click-to-call

## Static Click-to-call

Most common use case only need to connect a contact to a pre-determined destination, e.g.
a simple URL with just the contact number added to URL by the application.

Example can be a phone number hyperlink in a Chat application which upon click will dial
the phone number and connect it to a pre-determined agent.

In this type, you usually create the Click-to-call endpoint, you specify the
pre-determined extension, or phone number and which end to dial first.

You can now use the connect API request and use the Click-to-call ID to initiate the
call between the two endpoints.

## Dynamic Click-to-call

More advanced applications may need to decide on the parameters of Click-to-call without
needing to create the Click-to-call first.

This adds ability for these applications to dynamically generate the request for making
calls using Click-to-call in less static way and without requiring making multiple API
requests.

This dynamism may be useful only if the Click-to-call endpoint parameters must be decided on
per-call basis. If this is not the case for your application we highly suggest to use the
statically defined Click-to-call.

These applications can provide their Click-to-call doc in connect API request.

In this scenario:

1. The authentication of the API request is enforced
2. The user MUST provide a Click-to-call Object
3. You may combine this with Quick-to-call, in this case you won't need to set the
   extension as it is already assumed.

A few informations will be set in CDR's `custom_application_vars` of the legs involved in
this call, to indicates the Click-to-call was generated dynamically. This includes a
uniquely generated ID field `dynamic_clicktocall_id`. This ID can be used later to retrieve
the Click-to-call history.

The dynamic Click-to-call Object will be stored in the history under `dynamic_clicktocall.doc"
and can be retrieved using the history API.

#### Example

A request like:

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -H "Content-Type: application/json" \
    'http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/clicktocall/connect?contact={CONTACT}' \
    -d '{"data":{ "extension": "{AGENT_SMITH_EXT}", "outbond_caller_name": "Agent Smith", "name": "Dear Customer" }}'
```

Will dial `{AGENT_SMITH_EXT}` then dials the `{CONTACT}`.

## Quick-to-call: Custom Callflow execution

In Click-to-call object you may provide a custom Callflow Object or an ID to a
Callflow or provide the custom Callflow Object via `custom_application_vars` in
the connect API.

These parameters can be set in `custom_application_vars` field of the Click-to-call
object.

- `flow_doc`: A valid Callflow Object. You may provide this object
  as a string or as JSON object. In both cases the Callflow object is validated and converted to
  string.
- `flow_id`: Id of a Callflow

`custom_application_vars` from the body of the request (using method `POST`) will be merged on top of
`custom_application_vars` field from Click-to-call document (if any), meaning CAVs from request body
will override CAVs from document.

If both `flow_id` and `flow_doc` are set, Callflow will try opening `flow_id` first,
if the doc not found will attempt to use `flow_doc`.

When initiating the call using connect API with a custom Callflow few things are enforce:

1. The extension is force to `quicktocall`. You can still customize the Caller ID Number
   and Caller ID Name.
2. Dialing the contact first, e.g. `"dial_first": "contact"`
3. `auto_answer=true` will be enforced (if supported by the endpoint)

In this scenario the contact in the URL will be dialed first, then the custom Callflow will
be executed on the call.

A `quicktocall` field will be added to `custom_application_vars` of the CDRs. A
`quicktocall` object will be stored into history with provided flow ID or object.


#### Example

Using a Click-to-call object like (the `flow_doc` is expanded as JSON for easier read):

```json
{
    "name": "click_to_welcome",
    "extension": "irrelavant",
    "outbound_caller_id_name": "Agent Smith",
    "outbound_callee_id_number": "9999",
    "custom_application_vars": {
        "flow_doc": {
            "flow": {
                "module": "play",
                "data": {
                    "id": "welcome_new_user"
                }
            }
        }
    }
}
```

If a connect API using contact 1000 is invoked, the extension `irrelavant` will be ignored,
the `dial_first: contact` will be enforced. When the user answers the call, the media
at `welcome_new_user` will be played on the call. After that the call will end.


## Auto answer

Connect API accepts `auto_answer` string query with a boolean value. When set to `true`
`answer-after` will be set on `Call-Info` SIP header sent to the endpoint that is being dialed first. If
the endpoint supports this feature, this will cause the device to accept the call.


#### Schema

Click-to-call allows you to create URLs that can be POSTed to with a phone number or SIP URI and create a phone call from the provided contact information to a destination you have pre-determined.



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`auth_required` | Determines if this click to call requires valid auth-tokens when invoked | `boolean()` | `true` | `false` |  
`bypass_media` | Default bypass media mode (The string type is deprecated, please use this as a boolean) | `boolean() | string('auto' \| 'false' \| 'true')` |   | `false` |  
`caller_id_number` | Explicitly set caller id number | `string()` |   | `false` |  
`custom_application_vars./[a-zA-Z0-9\-_]+/` |   | `string()` |   | `false` |  
`custom_application_vars` | Key-value pairs to set as custom_application_vars on the channel | `object()` | `{}` | `false` |  
`custom_sip_headers.in` | Custom SIP Headers to be applied to calls inbound to Kazoo from the endpoint | [#/definitions/custom_sip_headers](#custom_sip_headers) |   | `false` |  
`custom_sip_headers.out` | Custom SIP Headers to be applied to calls outbound from Kazoo to the endpoint | [#/definitions/custom_sip_headers](#custom_sip_headers) |   | `false` |  
`custom_sip_headers.^[a-zA-z0-9_\-]+$` | The SIP header to add | `string() | boolean() | integer()` |   | `false` |  
`custom_sip_headers` | A property list of SIP headers | `object()` |   | `false` |  
`dial_first` | Determines what will be dialed first: extension or contact | `string('extension' \| 'contact')` |   | `false` |  
`extension` | The extension to connect to when the click to call is invoked | `string()` |   | `true` |  
`media.ignore_early_media` | The option to determine if early media from the endpoint should always be ignored | `boolean()` |   | `false` |  
`media` |   | `object()` |   | `false` |  
`music_on_hold.media_id` | The ID of a media object that should be used as the music on hold | `string(0..2048)` |   | `false` |  
`music_on_hold.options.[]` |   | `string('preserve-position' \| 'random-start')` |   | `false` |  
`music_on_hold.options` | Options for playing music on hold | `array(string('preserve-position' \| 'random-start'))` |   | `false` |  
`music_on_hold` | The music on hold parameters used if not a property of the device owner | `object()` |   | `false` |  
`name` | A friendly name for the click to call | `string(1..128)` |   | `true` |  
`outbound_callee_id_name` | Callee ID Name of the device calling out to the contact number | `string()` |   | `false` |  
`outbound_callee_id_number` | Callee ID Number of the device calling out to the contact number | `string()` |   | `false` |  
`presence_id` | Static presence ID (used instead of SIP username) | `string()` |   | `false` | `supported`
`ringback` | Ringback to use | `string()` |   | `false` |  
`throttle` | The rate that this click to call can be invoked | `integer()` |   | `false` |  
`timeout` | How long, in seconds, to wait for the call to progress | `integer()` |   | `false` |  
`whitelist.[]` |   | `string(1..)` |   | `false` |  
`whitelist` | A list of regular expressions that the click to call can dial to | `array(string(1..))` |   | `false` |  

### custom_sip_headers

Custom SIP headers applied to an INVITE


Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`^[a-zA-z0-9_\-]+$` | The SIP header to add | `string() | boolean() | integer()` |   | `false` |  



## List all Click-to-call endpoints

List all Click-to-call endpoints defined in the account.

> GET /v2/accounts/{ACCOUNT_ID}/clicktocall

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/clicktocall
```

```json
{
    "auth_token":"{AUTH_TOKEN}",
    "data": [
        {
            "extension": "{EXTENSION}",
            "id": "{C2C_ID}",
            "name": "{NAME}"
        }
    ],
    "node": "{NODE_HASH}",
    "page_size": 1,
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success",
    "timestamp": "{TIMESTAMP}",
    "version": "4.3.1"
}
```

## Create a clicktocall endpoint

> PUT /v2/accounts/{ACCOUNT_ID}/clicktocall

```shell
curl -v -X PUT \
    -H "Content-Type:application/json" \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data":{"name":"{NAME}, "extension":"{EXTENSION}"}}'
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/clicktocall
```

If your application need to trigger this Click-to-call in places that API authentication
is not possible, you may set `"auth_required": false`.

```json
{
    "auth_token":"{AUTH_TOKEN}",
    "data": {
        "custom_application_vars": {},
        "extension": "{EXTENSION}",
        "id": "{C2C_ID}",
        "name": "{NAME}"
    },
    "node": "{NODE_HASH}",
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success",
    "timestamp": "{TIMESTAMP}",
    "version": "4.3.1"
}
```

## Fetch

> GET /v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}
```

```json
{
    "auth_token":"{AUTH_TOKEN}",
    "data": {
        "auth_required": false,
        "custom_application_vars": {},
        "extension": "{EXTENSION}",
        "id": "{C2C_ID}",
        "name": "{NAME}"
    },
    "node": "{NODE_HASH}",
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success",
    "timestamp": "{TIMESTAMP}",
    "version": "4.3.1"
}

```

## Change

> POST /v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}

```shell
curl -v -X POST \
    -H "Content-Type:application/json" \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}
```

## Patch

> PATCH /v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}

```shell
curl -v -X PATCH \
    -H "Content-Type:application/json" \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}
```

## Remove

> DELETE /v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}

```shell
curl -v -X DELETE \
    -H "Content-Type:application/json" \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}
```

## List Click-to-call calls history

Each `/connect` API request will create a history entry with the result of originate
request of the call. The result does not necessary indicates the endpoints that dialed
first was answered or the call to destination was successful. It only provides that
result of origination request to the first dialed endpoint.

> GET /v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}/history

If the `/connect` request was triggered using Quick-To-call or used dynamic Click-to-call
the history will include fields with supplied information from the request.

To retrieve history for a dynamic Click-to-call, you first must look for its ID in the
CDRs. The dynamic ID will stored in CDRs `custom_application_vars` of involved legs.

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}/history
```

Sample response:

```json
{
  "page_size": 4,
  "metadata": {},
  "data": [
    {
      "timestamp": 63904800984,
      "contact": "{CONTACT}",
      "call_id": "c2c-820d8d81f7efa5dd-d62fddfd585b-bde4a071",
      "result": "success",
      "quicktocall": {
        "is_quicktocall": true,
        "quicktocall_flow": {
          "flow_id": "{FLOW_ID}"
        }
      },
      "id": "{HISTORY_ID}"
    },
    {
      "timestamp": 63904530884,
      "contact": "{CONTACT}",
      "call_id": "{CALL_ID}",
      "result": "success",
      "dynamic_clicktocall": {
        "is_dynamic_clicktocall": true,
        "doc": {
          "custom_application_vars": {
            "blocking": "true",
            "contact": "{CONTACT}",
            "dynamic_clicktocall_id": "c2c_6cbfd2633df0d9bf488df77a"
          },
          "name": "{NAME}",
          "outbound_callee_id_name": "{OUTBOUND_CALLEE_ID_NAME}",
          "outbound_callee_id_number": "{OUTBOUND_CALLEE_ID_NAME}",
          "auth_required": true,
          "extension": "{EXTENSION}",
          "id": "c2c_6cbfd2633df0d9bf488df77a"
        }
      },
      "id": "{HISTORY_ID}"
    },
    {
      "timestamp": 63904113867,
      "contact": "{CONTACT}",
      "call_id": "{CALL_ID}",
      "result": "success",
      "id": "{HISTORY_ID}"
    },
    {
      "timestamp": 63904113206,
      "contact": "{CONTACT}",
      "call_id": "{CALL_ID}",
      "result": "error",
      "cause": "NO_ROUTE_DESTINATION",
      "id": "{HISTORY_ID}"
    }
  ]
}
```

## Connect the Click-to-call endpoint with a supplied number

This endpoint behaves exactly same as its counterpart with payload but using HTTP method `GET`
instead of `POST`, so there is no request body and all parameters must supplied using
string query.

To see further information see the `POST` endpoint below.

> GET /v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}/connect

Example:

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}/connect?contact={CONTACT}
```

## Connect the Click-to-call endpoint with a supplied number and a payload

Connect API will execute a call to connect the extension to the contact number supplied on the
URL.

You may also include a custom flow to be executed instead of dialing the extension. In
case, you supply a Callflow document ID in `flow_id` or a full valid custom Callflow
object in `flow_doc` under the `custom_application_vars` field. This can be set either in
the request payload of `POST` request to connect API endpoint or it can be stored in the
Click-to-call document itself. See [Quick-To-call](#quick-to-call-custom-callflow-execution]
above for more information.

> POST /v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}/connect


### Non-blocking version

You may execute the clicktocall in non-blocking fashion. In this case the dial to the
extension and contact will executed in the background the API request to the Connect API
will return immediately with a 202 HTTP status code and the originate request as response payload.

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}/connect?contact={CONTACT}
```

Response example:

```json
    "data": {
        "application_data": {
            "route": "{CONTACT}"
        },
        "application_name": "transfer",
        "continue_on_fail": true,
        "custom_application_vars": {
            "contact": "{CONTACT}"
        },
        "custom_channel_vars": {
            "account_id": "{ACCOUNT_ID}",
            "authorizing_id": "{C2C_ID}",
            "authorizing_type": "clicktocall",
            "auto_answer_loopback": true,
            "from_uri": "{EXTENSION}@{ACCOUNT_REALM}",
            "inherit_codec": false,
            "loopback_request_uri": "{CONTACT}@{ACCOUNT_REALM}",
            "request_uri": "{CONTACT}@{ACCOUNT_REALM}",
            "retain_cid": true
        },
        "dial_endpoint_method": "single",
        "endpoints": [
            {
                "invite_format": "loopback",
                "route": "{EXTENSION}",
                "to_did": "{EXTENSION}",
                "to_realm": "{ACCOUNT_REALM}"
            }
        ],
        "export_custom_channel_vars": [
            "Account-ID",
            "Authorizing-ID",
            "Authorizing-Type",
            "Loopback-Request-URI",
            "From-URI",
            "Request-URI"
        ],
        "ignore_early_media": true,
        "loopback_bowout": "false",
        "outbound_call_id": "c2c-{TRUNCATED_REQ_ID}-{TRUNCATED_C2C_ID}-{RANDOM}",
        "outbound_callee_id_name": "{EXTENSION}",
        "outbound_callee_id_number": "{EXTENSION}",
        "outbound_caller_id_name": "{C2C NAME}",
        "outbound_caller_id_number": "{CONTACT}",
        "simplify_loopback": "false",
        "start_control_process": "false",
        "timeout": 30
    },
    "node": "{NODE_HASH}",
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success",
    "timestamp": "{TIMESTAMP}",
    "version": "4.3.1"
}

```

### Blocking version

In this version, the HTTP to call to `/connect` endpoint API will be blocked until the
originate request to connect the two endpoint returns. The response does not necessary
means the call was successful, or the dialed first endpoint answered the call.

The response is the Click-to-call history unlike the originate request in the
Non-blocking version.

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/clicktocall/{C2C_ID}/connect?contact={CONTACT}&blocking=true
```

See the `/history` API above for response example

## Connect a dynamic Click-to-call endpoint with a supplied number

If you application to decide on Click-to-call endpoint parameters on per-call basis,
you may consider to just connect the two endpoints without extraneous call to create the Click-to-call
document. If this is not the case for your application we highly suggest to use the
statically defined Click-to-call and use one of the `/connect` APIs above.

These applications can provide their Click-to-call doc in connect API request. See the
[Dynamic Click-to-call](#dynamic-click-to-call) above for more.

> POST /v2/accounts/{ACCOUNT_ID}/clicktocall/connect

Other than using a temporary dynamic Click-to-call this API behaves similiar to
`POST /connect` API above.
