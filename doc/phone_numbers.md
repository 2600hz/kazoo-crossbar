# Phone Numbers API

## About Phone Numbers

The 2600Hz API for managing numbers.

### Per-number CRUD operations

- `{PHONE_NUMBER}` has to be URL-encoded
    * e.g. turn `+14155555555` into `%2B14155555555`
    * Note `4123456789` is turned into `+14123456789`
    * Note however, `41234567` is turned into `+41234567`, so be careful!
- To add/modify numbers, either:
    * Account document must be showing `pvt_wnm_allow_additions` as `true`
    * Or auth must be done via master account.

#### Schema

Schema for a number



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`carrier_name` | Name of the carrier provider | `string(1..30)` |   | `false` |  
`cnam.display_name` | Name that displayed in the callee side | `string(1..15)` |   | `false` |  
`cnam.inbound_lookup` | Lookup name that associated with the number in provider database and display it for inbound call | `boolean()` |   | `false` |  
`cnam` | Caller ID Name of a person or business that is placing a call | `object()` |   | `false` |  
`create_with_state` | The state to create numbers in | `string('aging' | 'available' | 'deleted' | 'discovery' | 'in_service' | 'port_in' | 'port_out' | 'released' | 'reserved')` |   | `false` |  
`e911.activated_time` | The time stamp e911 was provisioned | `string()` |   | `false` |  
`e911.caller_name` | The name that will show to emergency services | `string(3..)` |   | `false` |  
`e911.extended_address` | The suit/floor/apt. address where the number is in service | `string()` |   | `false` |  
`e911.latitude` | The e911 provisioning system calculated service address latitude | `string()` |   | `false` |  
`e911.legacy_data.house_number` | The name that will show to emergency services | `string()` |   | `false` |  
`e911.legacy_data.predirectional` | The name that will show to emergency services | `string()` |   | `false` |  
`e911.legacy_data.streetname` | The name that will show to emergency services | `string()` |   | `false` |  
`e911.legacy_data.suite` | The name that will show to emergency services | `string()` |   | `false` |  
`e911.legacy_data` | Legacy E911 information | `object()` |   | `false` |  
`e911.locality` | The locality (city) where the number is in service | `string()` |   | `true` |  
`e911.location_id` | The e911 provisioning system internal id for this service address | `string()` |   | `false` |  
`e911.longitude` | The e911 provisioning system calculated service address longitude | `string()` |   | `false` |  
`e911.notification_contact_emails.[]` |   | `string()` |   | `false` |  
`e911.notification_contact_emails` | A list of email addresses to receive notification when this number places an emergency call | `array(string())` | `[]` | `false` |  
`e911.plus_four` | The extended zip/postal code where the number is in service | `string()` |   | `false` |  
`e911.postal_code` | The zip/postal code where the number is in service | `string()` |   | `true` |  
`e911.region` | The region (state) where the number is in service | `string(2)` |   | `true` |  
`e911.status` | The e911 provisioning system status for this service address | `string('INVALID' | 'GEOCODED' | 'PROVISIONED' | 'REMOVED' | 'ERROR')` |   | `false` |  
`e911.street_address` | The street address where the number is in service | `string()` |   | `true` |  
`e911` | E911 information for the current phone number | `object()` |   | `false` |  
`porting.billing_account_id` | The account id the losing carrier has on file | `string()` |   | `false` |  
`porting.billing_extended_address` | The suit/floor/apt. address the losing carrier has on file | `string()` |   | `false` |  
`porting.billing_locality` | The locality (city) the losing carrier has on file | `string()` |   | `false` |  
`porting.billing_name` | The name or company name the losing carrier has on file | `string()` |   | `false` |  
`porting.billing_postal_code` | The zip/postal code the losing carrier has on file | `string()` |   | `false` |  
`porting.billing_region` | The region (state) the losing carrier has on file | `string()` |   | `false` |  
`porting.billing_street_address` | The street address the losing carrier has on file | `string()` |   | `false` |  
`porting.billing_telephone_number` | The BTN of the account the number belongs to | `string()` |   | `false` |  
`porting.comments.[]` |   | `string()` |   | `false` |  
`porting.comments` | An array of comments | `array(string())` |   | `false` |  
`porting.customer_contact` | The phone number that can be used to contact the owner of the number | `string()` |   | `false` |  
`porting.port_id` | The id of the port request | `string()` |   | `false` |  
`porting.requested_port_date` | The requested port date | `string()` |   | `false` |  
`porting.service_provider` | The name of the losing carrier | `string()` |   | `false` |  
`porting` | Porting (in) information for the phone number | `object()` |   | `false` |  



## Search For Available Numbers On System

- `PREFIX`: a 3-digit number prefix or an URL-encoded e164 prefix (e.g. `499` or `%2B1499`)
- `QUANTITY`: maximum amount of numbers to be returned (e.g. `2`)
- `OFFSET`: page number (e.g. `0`)

> GET /v2/phone_numbers?prefix={PREFIX}&quantity={QUANTITY}&offset={OFFSET}&country={COUNTRY}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/phone_numbers?prefix=415&quantity=2
```

```json
{
    "auth_token": "",
    "metadata": {},
    "data": [
        {
            "e164": "+14152338397",
            "formatted_number": "1-415-233-8397",
            "npa_nxx": "415233",
            "number": "+14152338397",
            "number_id": "4AA418FB-3409-4340-8210-E7EAFE2AB118",
            "rate_center": {
                "lata": "722",
                "name": "SAN RAFAEL",
                "state": "CA"
            },
            "status": "Available",
            "ten_digit": "4152338397"
        },
        {
            "e164": "+14152338421",
            "formatted_number": "1-415-233-8421",
            "npa_nxx": "415233",
            "number": "+14152338421",
            "number_id": "0CD68E85-F149-477F-9C13-1E720ACCC3EE",
            "rate_center": {
                "lata": "722",
                "name": "SAN RAFAEL",
                "state": "CA"
            },
            "status": "Available",
            "ten_digit": "4152338421"
        }
    ],
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```

## Search for available numbers you own

- `PREFIX`: a 3-digit number prefix or an URL-encoded e164 prefix (e.g. `499` or `%2B1499`)
- `QUANTITY`: maximum amount of numbers to be returned (e.g. `2`)
- `OFFSET`: page number (e.g. `0`)

> GET /v2/accounts/{ACCOUNT_ID}/phone_numbers?prefix={PREFIX}&quantity={QUANTITY}&offset={OFFSET}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers?prefix=555&quantity=3&offset=6
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": {},
    "data": [
        {
            "number": "+15552225562",
            "state": "available"
        },
        {
            "number": "+15554445558",
            "state": "discovery"
        },
        {
            "number": "+15552225562",
            "state": "available"
        }
    ],
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```

## See How Many Digits A `{PREFIX}` Can Take

> GET /v2/accounts/{ACCOUNT_ID}/phone_numbers/carriers_info

Depending on your carriers configuration you may be allowed to query numbers
by NPA-NXX instead of just NPA.

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/carriers_info
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "meta_data": "{META_DATA}",
    "data": {
        "maximal_prefix_length": 3,
        "usable_carriers": [
            "bandwidth2",
            "bandwidth",
            "inum",
            "local",
            "inventory",
            "managed",
            "mdn",
            "other",
            "simwood",
            "telnyx",
            "vitelity",
            "voip_innovations"
        ],
        "usable_creation_states": [
            "aging",
            "available",
            "in_service",
            "port_in",
            "reserved"
        ]
    },
    "node": "{NODE}",
    "request_id": "{REQUEST_ID}",
    "status": "success",
    "timestamp": "2024-04-12T14:04:37Z",
    "version": "4.0.0"
}
```

## List Account's Phone Numbers

This lists the numbers an account owns, along with their properties.

!!! note
    one can apply filters such as `?filter_state=in_service` or `?created_from=63627345744`

> GET /v2/accounts/{ACCOUNT_ID}/phone_numbers

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers?page_size=2&start_key=%2B14152338421
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "meta_data": "{META_DATA}",
    "data": {
        "cascade_quantity": 1,
        "numbers": {
            "+14152338421": {
                "state": "in_service",
                "features": [],
                "features_allowed": [],
                "features_denied": [],
                "assigned_to": "{ACCOUNT_ID}",
                "created": 63628550806,
                "updated": 63628550806,
                "features_available":[
                    "carrier_name",
                    "cnam",
                    "e911",
                    "force_outbound",
                    "inbound_cnam",
                    "outbound_cnam",
                    "port",
                    "prepend",
                    "ringback"
                    ]
            },
            "+14152338397": {
                "state":"reserved",
                "features": [
                    "local"
                ],
                "features_allowed": [],
                "features_denied": [],
                "assigned_to": "{ACCOUNT_ID}",
                "created": 63880145085,
                "updated": 63880145085,
                "features_available": [
                    "carrier_name",
                    "force_outbound",
                    "prepend",
                    "ringback"
                ]
            }
        }
    },
    "next_start_key": "{NEXT_START_KEY}",
    "page_size": 2,
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```

## Remove a number from the account owning it

> DELETE /v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}
```

### Response

**Success**

```json
{
  "auth_token": "{AUTH_TOKEN}",
  "metadata": {
        "modified": 63880388893,
        "id": "{PHONE_NUMBER}",
        "features": {
            "settings": {},
            "available": [
                "force_outbound",
                "prepend",
                "ringback"
            ]
        },
        "created": 63880369851,
        "carrier_module": "bandwidth2",
        "deleted": true
    },
  "data": {
        "id": "{PHONE_NUMBER}",
        "state": "available"
  },
  "request_id": "{REQUEST_ID}",
  "revision": "{REVISION}",
  "status": "success"
}
```

**Number not in account**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": {},
    "data": {
        "message": "bad identifier",
        "not_found": "The number could not be found",
        "cause": "{PHONE_NUMBER}"
    },
    "error": "404",
    "message": "bad_identifier",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```


## Remove A Number From Account (admin Only)

> DELETE /v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}?hard=true
```

**Response**

```json
{
  "auth_token": "{AUTH_TOKEN}",
    "metadata": {
        "modified": 63880152016,
        "id": "{PHONE_NUMBER}",
        "features": {
            "settings": {},
            "available": [
                "carrier_name",
                "cnam",
                "e911",
                "force_outbound",
                "inbound_cnam",
                "outbound_cnam",
                "port",
                "prepend",
                "ringback"
            ]
        },
        "created": 63863803040,
        "carrier_module": "bandwidth2",
        "deleted": true
    },
    "data": {
        "ui_metadata": {
            "version": "5.2-3",
            "ui": "monster-ui",
            "origin": "common"
        },
        "id": "{PHONE_NUMBER}",
        "state": "deleted"
    },
  "request_id": "{REQUEST_ID}",
  "revision": "{REVISION}",
  "status": "success"
}
```


## List An Account's Specific Phone Number

Show the number's properties along with user-defined properties.

> GET /v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}
```

**Success Response**

```json
{
  "auth_token": "{AUTH_TOKEN}",
  "metadata": {
        "modified": 63880152996,
        "id": "{PHONE_NUMBER}",
        "features": {
            "settings": {},
            "available": [
                "carrier_name",
                "force_outbound",
                "prepend",
                "ringback"
            ]
        },
        "created": 63880145085,
        "carrier_module": "local"
    },
  "data": {
        "ui_metadata": {
            "version": "5.2-3",
            "ui": "monster-ui",
            "origin": "common"
        },
        "id": "{PHONE_NUMBER}",
        "features": [
            "local"
        ],
        "my_own_fields": {
        },
        "used_by": "callflow",
        "state": "reversed"
    },
  "request_id": "{REQUEST_ID}",
  "revision": "{REVISION}",
  "status": "success"
}
```

**Failure Response**

Possible reasons for failure:

* Account does not have enough privileges to read number
* Number does not exist

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadate": {},
    "data": {
        "message": "bad identifier",
        "not_found": "The number could not be found",
        "case": "{PHONE_NUMBER}"
    },
    "error": "404",
    "message": "bad_identifier",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```


## Update Public Fields Of A Number

!!! note
    some public fields are used to configure number features.

> POST /v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data":{"my_own_field":"some other value", "cnam":{"display_name":"My caller ID", "inbound_lookup":true}}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}
```

```json
{
  "auth_token": "{AUTH_TOKEN}",
  "metadata": {
        "modified": 63880390159,
        "id": "{PHONE_NUMBER}",
        "features": {
            "settings": {},
            "available": [
                "cnam",
                "e911",
                "force_outbound",
                "inbound_cnam",
                "outbound_cnam",
                "port",
                "prepend",
                "ringback"
            ]
        },
        "created": 63880369851,
        "carrier_module": "bandwidth2"
    },
  "data": {
        "my_own_field": "some other value",
        "cnam": {
            "inbound_lookup": true,
            "display_name": "My caller ID"
        },
        "id": "{PHONE_NUMBER}",
        "features": [
            "inbound_cnam",
            "outbound_cnam"
        ],
        "state": "in_service"
    },
  "request_id": "{REQUEST_ID}",
  "revision": "{REVISION}",
  "status": "success"
}
```

## Patch Public Fields Of A Number

> PATCH /v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}

```shell
curl -v -X PATCH \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data":{"my_own_field":42}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}
```

```json
{
  "auth_token": "{AUTH_TOKEN}",
  "metadata": {
        "modified": 63880390308,
        "id": "{PHONE_NUMBER}",
        "features": {
            "settings": {},
            "available": [
                "cnam",
                "e911",
                "force_outbound",
                "inbound_cnam",
                "outbound_cnam",
                "port",
                "prepend",
                "ringback"
            ]
        },
        "created": 63880369851,
        "carrier_module": "bandwidth2"
    },
  "data": {
        "my_own_field": 42,
        "cnam": {
            "inbound_lookup": true,
            "display_name": "My caller ID"
        },
        "id": "{PHONE_NUMBER}",
        "features": [
            "inbound_cnam",
            "outbound_cnam"
        ],
        "state": "in_service"
    },
  "request_id": "{REQUEST_ID}",
  "revision": "{REVISION}",
  "status": "success"
}
```

## Add a number to the database

Adds a number to the database, returning its properties.

!!! note
    Set field `"create_with_state"` in payload to your desired number state (defaults to `"in_service"`).

!!! note
    Payload is optional.

> PUT /v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data": {"my_own_field": {}}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}
```

### Success Response

```json
{
  "auth_token": "{AUTH_TOKEN}",
  "metadata": {
        "modified": 63880412858,
        "id": "{PHONE_NUMBER}",
        "features": {
            "settings": {},
            "available": [
                "carrier_name",
                "force_outbound",
                "prepend",
                "ringback"
            ]
        },
        "created": 63880412858,
        "carrier_module": "local"
    },
    "data": {
        "my_own_field": {},
        "id": "{PHONE_NUMBER}",
        "features": [
            "local"
        ],
        "state": "in_service"
    },
  "request_id": "{REQUEST_ID}",
  "revision": "{REVISION}",
  "status": "success"
}
```

### Failure Responses

**Number already exists**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": {},
    "data": {
        "cause": "{PHONE_NUMBER}",
        "code": 409,
        "error": "number_exists",
        "message": "number {PHONE_NUMBER} already exists"
    },
    "error": "409",
    "message": "number_exists",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```

**Number does not conform to E.164 format**

A non-conforming `{PHONE_NUMBER}`: `"+141510010+15"`.

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": {},
    "data": {
        "cause": "{PHONE_NUMBER}",
        "code": 400,
        "error": "not_reconcilable",
        "message": "number {PHONE_NUMBER} is not reconcilable"
    },
    "error": "404",
    "message": "not_reconcilable",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```

**Account unauthorized**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": {},
    "data": {
        "code": 403,
        "error": "forbidden",
        "cause": "creating number in state 'in_service' is not allowed",
        "message": "requestor is unauthorized to perform operation"
    },
    "error": "403",
    "message": "forbidden",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```


## Check Availability Of Phone Numbers

> POST /v2/accounts/{ACCOUNT_ID}/phone_numbers/check

This API checks if the numbers are still available for purchase.

A status of `"error"` may be due to:

* Number not being handled by carrier `knm_other`
* `PhoneBook` being unresponsive

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data": {"numbers": [{PHONE_NUMBER1}, {PHONE_NUMBER2}]}}'
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/check
```

**Response**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "meta_data": {},
    "data": {
        "{PHONE_NUMBER1}": "success",
        "{PHONE_NUMBER2}": "error"
    },
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```


## Get Locality Information For A Collection Of Numbers

### PhoneBook

Phonebook is an external service that "abstract" carrier number inventory and the sysadmin need to provide and configure it for this API endpoint to work.

> POST /v2/accounts/{ACCOUNT_ID}/phone_numbers/locality

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data":{"numbers": ["{PHONE_NUMBER1}", "{PHONE_NUMBER2}"]}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/locality
```

**Success Response**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": {
        "{PHONE_NUMBER1}": {
            "carrier": {
                "company": "T-Mobile USA Inc",
                "dba": "T-Mobile USA Inc",
                "id": "6529",
                "type": "WIRELESS"
            },
            "country": "US",
            "e164_number": "{PHONE_NUMBER1}",
            "geocode": {
                "locality": "California"
            },
            "locality": {
                "alt_postal_codes": [
                    "94965",
                    "94941"
                ],
                "extended_postal_code": null,
                "latitude": "37.8725359094361",
                "locality": "Belvedere",
                "longitude": "-122.465900466078",
                "postal_code": "94920",
                "province": "CA",
                "switch": "OKLECAZVGT0",
                "type": "WIRELESS"
            },
            "number": "{PHONE_NUMBER1}",
            "status": "success"
        },
        "{PHONE_NUMBER2}": {
            "carrier": {
                "company": "Bandwidth.com CLEC LLC - CA",
                "dba": "Bandwidth.com CLEC LLC",
                "id": "981E",
                "type": "CLEC"
            },
            "country": "US",
            "e164_number": "{PHONE_NUMBER2}",
            "geocode": {
                "locality": "California"
            },
            "locality": {
                "alt_postal_codes": [
                    "94939",
                    "94976"
                ],
                "extended_postal_code": null,
                "latitude": "37.9267845442655",
                "locality": "Corte Madera",
                "longitude": "-122.527924297914",
                "postal_code": "94904",
                "province": "CA",
                "switch": "SNFCCA21XUY",
                "type": "LANDLINE"
            },
            "number": "{PHONE_NUMBER2}",
            "status": "success"
        }
    },
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```

**Backend to PhoneBook not set up**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": {},
    "data": "Unable to acquire numbers missing carrier url",
    "error": "500",
    "message": "init failed",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```


## List Available Numbers Of A Given US City

> GET /v2/accounts/{ACCOUNT_ID}/phone_numbers/prefix

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/prefix?city={CITY}
```

**Success Response**

```json

```

**Country or city not found**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": {
        "data": {},
        "error": 404,
        "message": "Not Found",
        "status": "error"
    },
    "error": "500",
    "message": "init failed",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```

**Backend to PhoneBook not set up**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": "Unable to acquire numbers missing carrier url",
    "error": "500",
    "message": "init failed",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```


## Remove a list of numbers from the database

> DELETE /v2/accounts/{ACCOUNT_ID}/phone_numbers/collection

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data":{"numbers": ["{PHONE_NUMBER1}", "{PHONE_NUMBER2}", "{PHONE_NUMBER3}"]}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/collection
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": {},
    "data": {
        "success": {
            "{PHONE_NUMBER1}": {
                "id": "{PHONE_NUMBER1}",
                "features": [
                    "local"
                ],
                "state": "available",
                "_read_only": {
                    "modified": 63880454152,
                    "id": "{PHONE_NUMBER1}",
                    "features": {
                        "settings": {},
                        "available": [
                            "force_outbound",
                            "prepend",
                            "ringback"
                        ]
                    },
                    "created": 63880145085,
                    "carrier_module": "local"
                }
            },
            "{PHONE_NUMBER2}": {
                "id": "{PHONE_NUMBER2}",
                "state": "available",
                "_read_only": {
                    "modified": 63880454152,
                    "id": "{PHONE_NUMBER2}",
                    "features": {
                        "settings": {},
                        "available": [
                            "force_outbound",
                            "prepend",
                            "ringback"
                        ]
                    },
                    "created": 63880369851,
                    "carrier_module": "bandwidth2"
                }
            },
            "{PHONE_NUMBER3}": {
                "id": "{PHONE_NUMBER3}",
                "state": "available",
                "_read_only": {
                    "modified": 63880454152,
                    "id": "{PHONE_NUMBER3}",
                    "features": {
                        "settings": {},
                        "available": [
                            "force_outbound",
                            "prepend",
                            "ringback"
                        ]
                    },
                    "created": 63880369851,
                    "carrier_module": "bandwidth2"
                }
            }
        },
        "error": []
    },
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```


## Remove a list of numbers from account (admin only)

> DELETE /v2/accounts/{ACCOUNT_ID}/phone_numbers/collection

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data":{"numbers": ["{PHONE_NUMBER1}", "{PHONE_NUMBER2}", "{PHONE_NUMBER3}"]}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/collection?hard=true
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": {},
    "data": {
        "success": {
            "{PHONE_NUMBER1}": {
                "myfield": 1337,
                "id": "{PHONE_NUMBER1}",
                "state": "deleted",
                "_read_only": {
                    "modified": 63880454928,
                    "id": "{PHONE_NUMBER1}",
                    "features": {
                        "settings": {},
                        "available": [
                            "carrier_name",
                            "cnam",
                            "e911",
                            "force_outbound",
                            "inbound_cnam",
                            "outbound_cnam",
                            "port",
                            "prepend",
                            "ringback"
                        ]
                    },
                    "created": 63880369851,
                    "carrier_module": "bandwidth2"
                }
            },
            "{PHONE_NUMBER2}": {
                "my_global_field": 12345,
                "id": "{PHONE_NUMBER2}",
                "features": [
                    "local"
                ],
                "state": "deleted",
                "_read_only": {
                    "modified": 63880454928,
                    "id": "{PHONE_NUMBER2}",
                    "features": {
                        "settings": {},
                        "available": [
                            "carrier_name",
                            "force_outbound",
                            "prepend",
                            "ringback"
                        ]
                    },
                    "created": 63880383793,
                    "carrier_module": "local"
                }
            },
            "{PHONE_NUMBER3}": {
                "my_global_field": 12345,
                "id": "{PHONE_NUMBER3}",
                "features": [
                    "local"
                ],
                "state": "deleted",
                "_read_only": {
                    "modified": 63880454928,
                    "id": "{PHONE_NUMBER3}",
                    "features": {
                        "settings": {},
                        "available": [
                            "carrier_name",
                            "force_outbound",
                            "prepend",
                            "ringback"
                        ]
                    },
                    "created": 63880383793,
                    "carrier_module": "local"
                }
            }
        },
        "error": []
    },
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```


## Update public fields of a list of numbers

> POST /v2/accounts/{ACCOUNT_ID}/phone_numbers/collection

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data": {"numbers": ["{PHONE_NUMBER1}", "{PHONE_NUMBER2}"], "myfield": 1337}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/collection
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": {},
    "data": {
        "success": {
            "+14157770055": {
                "myfield": 1337,
                "id": "{PHONE_NUMBER1}",
                "state": "in_service",
                "_read_only": {
                    "modified": 63880415140,
                    "id": "{PHONE_NUMBER1}",
                    "features": {
                        "settings": {},
                        "available": [
                            "carrier_name",
                            "cnam",
                            "e911",
                            "force_outbound",
                            "inbound_cnam",
                            "outbound_cnam",
                            "port",
                            "prepend",
                            "ringback"
                        ]
                    },
                    "created": 63880369851,
                    "carrier_module": "bandwidth2"
                }
            },
            "+13050038901": {
                "myfield": 1337,
                "id": "{PHONE_NUMBER2}",
                "features": [
                    "local"
                ],
                "state": "port_in",
                "_read_only": {
                    "modified": 63880415140,
                    "id": "{PHONE_NUMBER2}",
                    "features": {
                        "settings": {},
                        "available": [
                            "carrier_name",
                            "force_outbound",
                            "prepend",
                            "ringback"
                        ]
                    },
                    "created": 63880371131,
                    "carrier_module": "local"
                }
            }
        },
        "error": []
    },
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```


## Patch public fields of a list of numbers

> PATCH /v2/accounts/{ACCOUNT_ID}/phone_numbers/collection

```shell
curl -v -X PATCH \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data": {"numbers": ["{PHONE_NUMBER1}", "{PHONE_NUMBER2}"], "my_global_field": 12345}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/collection
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": {},
    "data": {
        "success": {
            "{PHONE_NUMBER1}": {
                "my_global_field": 12345,
                "id": "{PHONE_NUMBER1}",
                "features": [
                    "local"
                ],
                "state": "in_service",
                "_read_only": {
                    "modified": 63880384092,
                    "id": "{PHONE_NUMBER1}",
                    "features": {
                        "settings": {},
                        "available": [
                            "carrier_name",
                            "force_outbound",
                            "prepend",
                            "ringback"
                        ]
                    },
                    "created": 63880383793,
                    "carrier_module": "local"
                }
            },
            "{PHONE_NUMBER2}": {
                "my_global_field": 12345,
                "id": "{PHONE_NUMBER2}",
                "features": [
                    "local"
                ],
                "state": "in_service",
                "_read_only": {
                    "modified": 63880384092,
                    "id": "{PHONE_NUMBER2}",
                    "features": {
                        "settings": {},
                        "available": [
                            "carrier_name",
                            "force_outbound",
                            "prepend",
                            "ringback"
                        ]
                    },
                    "created": 63880383793,
                    "carrier_module": "local"
                }
            }
        },
        "error": []
    },
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```


## Add a list of numbers to the database

Note: set field `"create_with_state"` in payload to your desired number state (defaults to `"in_service"`).

> PUT /v2/accounts/{ACCOUNT_ID}/phone_numbers/collection

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data":{"numbers": ["{PHONE_NUMBER1}", "{PHONE_NUMBER2}", "{PHONE_NUMBER3}"]}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/collection
```

**Success Response**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": "{META_DATA}",
    "data": {
        "success": {
            "{PHONE_NUMBER1}": {
                "id": "{PHONE_NUMBER1}",
                "features": [
                    "local"
                ],
                "state": "in_service",
                "_read_only": {
                    "modified": 63880383793,
                    "id": "{PHONE_NUMBER1}",
                    "features": {
                        "settings": {},
                        "available": [
                            "carrier_name",
                            "force_outbound",
                            "prepend",
                            "ringback"
                        ]
                    },
                    "created": 63880383793,
                    "carrier_module": "local"
                }
            },
            "{PHONE_NUMBER2}": {
                "id": "{PHONE_NUMBER2}",
                "features": [
                    "local"
                ],
                "state": "in_service",
                "_read_only": {
                    "modified": 63880383793,
                    "id": "{PHONE_NUMBER2}",
                    "features": {
                        "settings": {},
                        "available": [
                            "carrier_name",
                            "force_outbound",
                            "prepend",
                            "ringback"
                        ]
                    },
                    "created": 63880383793,
                    "carrier_module": "local"
                }
            }
        }
    },
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```

**Failure**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": {},
    "data": {
        "success": {},
        "error": {
            "+14157770012": {
                "code": 409,
                "error": "number_exists",
                "cause": "{PHONE_NUMBER1}",
                "message": "number {PHONE_NUMBER1} already exists"
            },
            "+14157770022": {
                "code": 409,
                "error": "number_exists",
                "cause": "{PHONE_NUMBER2}",
                "message": "number {PHONE_NUMBER2} already exists"
            }
        }
    },
    "request_id": "{REQUEST_ID}"
}
```


## List classifiers

> GET /v2/accounts/{ACCOUNT_ID}/phone_numbers/classifiers

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/classifiers
```

```json
{
  "auth_token": "{AUTH_TOKEN}",
  "metadata": "{META_DATA}",
  "data": [
    {
      "name": "caribbean",
      "friendly_name": "Caribbean",
      "pretty_print": "SS(###) ###-####",
      "regex": "^\\+?1((?:684|264|268|242|246|441|284|345|767|809|829|849|473|671|876|664|670|787|939|869|758|784|721|868|649|340)\\d{7})$"
    },
    {
      "name": "did_us",
      "friendly_name": "US DID",
      "pretty_print": "SS(###) ###-####",
      "regex": "^\\+?1?([2-9][0-9]{2}[2-9][0-9]{6})$"
    },
    {
      "name": "emergency",
      "friendly_name": "Emergency Dispatcher",
      "regex": "^(911)$"
    },
    {
      "name": "international",
      "friendly_name": "International",
      "regex": "^(011\\d*)$|^(00\\d*)$"
    },
    {
      "name": "toll_us",
      "friendly_name": "US Toll",
      "pretty_print": "SS(###) ###-####",
      "regex": "^\\+1(900\\d{7})$"
    },
    {
      "name": "tollfree_us",
      "friendly_name": "US TollFree",
      "pretty_print": "SS(###) ###-####",
      "regex": "^\\+1((?:800|888|877|866|855)\\d{7})$"
    },
    {
      "name": "unknown",
      "friendly_name": "Unknown",
      "regex": "^(.*)$"
    }
  ],
  "request_id": "{REQUEST_ID}",
  "revision": "{REVISION}",
  "status": "success"
}
```


## Fix issues

> POST /v2/accounts/{ACCOUNT_ID}/phone_numbers/fix

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/fix
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": "{META_DATA}",
    "data": {
        "numbers": {
            "+14157771155": {
                "state": "reserved",
                "features": [],
                "features_allowed": [],
                "features_denied": [],
                "assigned_to": "{ACCOUNT_ID}",
                "created": 63880369851,
                "updated": 63880370278,
                "features_available": [
                    "carrier_name",
                    "cnam",
                    "e911",
                    "force_outbound",
                    "inbound_cnam",
                    "outbound_cnam",
                    "port",
                    "prepend",
                    "ringback"
                ]
            },
            "+14157770055": {
                "state": "in_service",
                "features": [],
                "features_allowed": [],
                "features_denied": [],
                "assigned_to": "{ACCOUNT_ID}",
                "created": 63880369851,
                "updated": 63880369851,
                "features_available": [
                    "carrier_name",
                    "cnam",
                    "e911",
                    "force_outbound",
                    "inbound_cnam",
                    "outbound_cnam",
                    "port",
                    "prepend",
                    "ringback"
                ]
            }
        },
        "cascade_quantity": 2
    },
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```


## Fix `used_by` field (and others) of a specific number

> POST /v2/accounts/{ACCOUNT_ID}/phone_numbers/fix/{PHONE_NUMBER}

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/fix/%2B15554445563
```

```json
{
  "auth_token": "{AUTH_TOKEN}",
  "metadata": {},
  "data": {},
  "request_id": "{REQUEST_ID}",
  "revision": "{REVISION}",
  "status": "success"
}
```

## Return which account a number belongs to

> GET /v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}/identify

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}/identify
```

**Success Response**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": "{META_DATA}",
    "data": {
        "account_id": "account0000000000000000000000002",
        "number": "{PHONE_NUMBER}"
    },
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```

**Number not in service or account disabled**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": "{META_DATA}",
    "data": {
        "account_id": "009deaaadc97b2ae693c6cc4920988e8",
        "cause": "not_in_service"
    },
    "error": "400",
    "message": "client error",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```

**Number not found or not enough privileges**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": "{META_DATA}",
    "data": {
        "message": "bad identifier",
        "not_found": "The number could not be found"
    },
    "error": "404",
    "message": "bad_identifier",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```


## Create a number in the `port_in` state

> PUT /v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}/port

```shell
curl -v -X PUT \
     -H "X-Auth-Token: {AUTH_TOKEN}" \
     -d '{"data": {"blip": 432}}' \
     http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}/port
```

```json
{
  "auth_token": "{AUTH_TOKEN}",
  "metadata": {
        "modified": 63880371131,
        "id": "{PHONE_NUMBER}",
        "features": {
            "settings": {},
            "available": [
                "carrier_name",
                "force_outbound",
                "prepend",
                "ringback"
            ]
        },
        "created": 63880371131,
        "carrier_module": "local"
    },
    "data": {
        "blip": 432,
        "id": "{PHONE_NUMBER}",
        "features": [
            "local"
        ],
        "state": "port_in"
    },
  "request_id": "{REQUEST_ID}",
  "revision": "{REVISION}",
  "status": "success"
}
```

## Move a number to the reserved state

> PUT /v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}/reserve

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}/reserve
```

**Success Response**

```json
{
  "auth_token": "{AUTH_TOKEN}",
    "metadata": {
        "modified": 63880369479,
        "id": "{PHONE_NUMBER}",
        "features": {
            "settings": {},
            "available": [
                "carrier_name",
                "force_outbound",
                "prepend",
                "ringback"
            ]
        },
        "created": 63880145085,
        "carrier_module": "local"
    },
    "data": {
        "ui_metadata": {
            "version": "5.2-3",
            "ui": "monster-ui",
            "origin": "common"
        },
        "id": "{PHONE_NUMBER}",
        "features": [
            "local"
        ],
        "state": "reserved"
    },
  "request_id": "{REQUEST_ID}",
  "revision": "{REVISION}",
  "status": "success"
}
```

**Number already in reserved state**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": "{META_DATA}",
    "data": {
        "code": 400,
        "error": "no_change_required",
        "message": "no change required"
    },
    "error": "400",
    "message": "no_change_required",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```

**Number does not exist**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": "{META_DATA}",
    "data": {
        "message": "bad identifier",
        "not_found": "The number could not be found"
    },
    "error": "404",
    "message": "bad_identifier",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```

## Buy a number once searched for

Note: one is not charged if number is already in service.

> PUT /v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}/activate

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/{PHONE_NUMBER}/activate
```

**Success**

```json
{
  "auth_token": "{AUTH_TOKEN}",
  "metadata": {
        "modified": 63880482878,
        "id": "{PHONE_NUMBER}",
        "features": {
            "settings": {},
            "available": [
                "carrier_name",
                "force_outbound",
                "prepend",
                "ringback"
            ]
        },
        "created": 63880482866,
        "carrier_module": "local"
    },
    "data": {
        "id": "{PHONE_NUMBER}",
        "features": [
            "local"
        ],
        "state": "in_service"
    },
  "request_id": "{REQUEST_ID}",
  "revision": "{REVISION}",
  "status": "success"
}
```

**Number was not returned in previous search results or other error**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": {
        "code": 500,
        "error": "unspecified_fault",
        "message": "missing_provider_url"
    },
    "error": "500",
    "message": "unspecified_fault",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```

**Carrier fault**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": {
        "cause": "{PHONE_NUMBER}",
        "code": 500,
        "error": "unspecified_fault",
        "message": "fault by carrier"
    },
    "error": "500",
    "message": "unspecified_fault",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```

## Classify a number

> GET /v2/accounts/{ACCOUNT_ID}/phone_numbers/classifiers/{PHONE_NUMBER}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/classifiers/{PHONE_NUMBER}
```

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": "{META_DATA}",
    "data": {
        "e164": "+1{PHONE_NUMBER}",
        "friendly_name": "US DID",
        "name": "did_us",
        "number": "{PHONE_NUMBER}",
        "pretty_print": "SS(###) ###-####",
        "regex": "^\\+?1?([2-9][0-9]{2}[2-9][0-9]{6})$"
    },
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```


## Buy a list of numbers

Note: numbers must have appeared as part of the results of a numbers search.

> PUT /v2/accounts/{ACCOUNT_ID}/phone_numbers/collection/activate

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data":{"numbers": ["{PHONE_NUMBER1}", "{PHONE_NUMBER2}"]}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/collection/activate
```

**Success Response**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "metadata": {},
    "data": {
        "success": {
            "+14167775544": {
                "id": "{PHONE_NUMBER1}",
                "features": [
                    "local"
                ],
                "state": "in_service",
                "_read_only": {
                    "modified": 63880498842,
                    "id": "{PHONE_NUMBER1}",
                    "features": {
                        "settings": {},
                        "available": [
                            "carrier_name",
                            "force_outbound",
                            "prepend",
                            "ringback"
                        ]
                    },
                    "created": 63880498566,
                    "carrier_module": "local"
                }
            },
            "+14167775555": {
                "id": "{PHONE_NUMBER2}",
                "features": [
                    "local"
                ],
                "state": "in_service",
                "_read_only": {
                    "modified": 63880498842,
                    "id": "{PHONE_NUMBER2}",
                    "features": {
                        "settings": {},
                        "available": [
                            "carrier_name",
                            "force_outbound",
                            "prepend",
                            "ringback"
                        ]
                    },
                    "created": 63880498566,
                    "carrier_module": "local"
                }
            }
        },
        "error": []
    },
    "request_id": "{REQUEST_ID}",
    "revision": "{REVISION}",
    "status": "success"
}
```

**Number not found or other error**

```json
{
    "auth_token": "{AUTH_TOKEN}",
    "data": {
        "{PHONE_NUMBER2}": {
            "code": 500,
            "error": "unspecified_fault",
            "message": "missing_provider_url"
        }
    },
    "error": "400",
    "message": "client error",
    "request_id": "{REQUEST_ID}",
    "status": "error"
}
```


## E911

> POST /v2/accounts/{ACCOUNT_ID}/phone_numbers/{NUMBER}

With a sample payload like below:
```json
{
    "data": {
        "used_by": "callflow",
        "id": "{NUMBER}",
        "e911": {
            "caller_name": "{NAME}",
            "postal_code": "{ZIP_CODE}",
            "street_address": "{ADDRESS}",
            "extended_address": "{EXTENDED}",
            "locality": "{CITY}",
            "region": "{STATE}"
        }
    }
}
```

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{_ABOVE_SAMPLE_}' \
    'http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/phone_numbers/{NUMBER}'
```


### Responses

**Invalid address**

```json
{
    "data": {
        "address": {
            "invalid": {
                "cause": {
                    "caller_name": "{NAME}",
                    "postal_code": "{ZIP_CODE}",
                    "street_address": "{ADDRESS}",
                    "extended_address": "{EXTENDED}",
                    "locality": "{CITY}",
                    "region": "{STATE}"
                },
                "message": "Location is not geocoded"
            }
        }
    },
    "error": "400",
    "message": "invalid data",
    "status": "error"
}
```

**Multiple choice**

```json
{
    "data": {
        "multiple_choice": {
            "e911": {
                "cause": {
                    "postal_code": "{ZIP_CODE}",
                    "street_address": "{ADDRESS}",
                    "extended_address": "{EXTENDED}",
                    "locality": "{CITY}",
                    "region": "{STATE}"
                },
                "details": [{
                    "postal_code": "{ZIP_CODE}",
                    "street_address": "{ADDRESS}",
                    "extended_address": "{EXTENDED}",
                    "locality": "{CITY}",
                    "region": "{STATE}"
                }, {
                    "postal_code": "{ZIP_CODE}",
                    "street_address": "{ADDRESS}",
                    "extended_address": "{EXTENDED}",
                    "locality": "{CITY}",
                    "region": "{STATE}"
                }],
                "message": "more than one address found"
            }
        }
    },
    "error": "400",
    "message": "multiple_choice",
    "status": "error"
}
```

**Success**

```json
{
    "data": {
        "used_by": "callflow",
        "id": "{NUMBER}",
        "e911": {
            "street_address": "116 NATOMA ST",
            "extended_address": "APT 116",
            "caller_name": "Michel Mabel",
            "locality": "SAN FRANCISCO",
            "latitude": "37.786861",
            "longitude": "-122.399484",
            "location_id": "27578725",
            "plus_four": "3745",
            "postal_code": "94105",
            "region": "CA",
            "status": "PROVISIONED",
            "legacy_data": {
                "house_number": "116",
                "streetname": "NATOMA ST",
                "suite": "APT 116"
            }
        }
    },
    "status": "success"
}
```
