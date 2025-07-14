# Addresses

## About Addresses

#### Schema

Account, user or device addresses



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`emergency.additional_information` | Additional location information. Example: Room 543 | `string()` |   | `false` |  
`emergency.callback_cid_number` | 10-digit DID used as caller ID to PSAP, overrides CID | `string(10)` |   | `false` |  
`emergency.country` | The country is identified by the two-letter ISO 3166 code. Example: US | `string()` |   | `true` |  
`emergency.county` | County, parish, gun (JP), district (IN). Example: King's County | `string()` |   | `false` |  
`emergency.delivery_method` | How the emergency call is routed by the destination handler (not applicable to all providers) | `string('direct' \| 'three_way' \| 'security_desk')` |   | `false` |  
`emergency.floor` | Floor. Example: 4 | `integer()` |   | `false` |  
`emergency.house_number` | House number, numeric part only. Example: 123 | `integer()` |   | `true` |  
`emergency.house_number_suffix` | House number suffix. Example: A, 1/2 | `string()` |   | `false` |  
`emergency.latitude` | The geo-position of a location, north or south of the equator, using WGS84 formatting | `string(0..11)` |   | `false` |  
`emergency.locality` | City, township, shi (JP). Example: New York | `string()` |   | `true` |  
`emergency.location_identifier` | United States unique 10-digit number known as an E911 location identifier (ELIN) | `integer()` |   | `false` |  
`emergency.longitude` | The geo-position of a location, east or west of the prime meridian, using WGS84 formatting | `string(0..11)` |   | `false` |  
`emergency.name` | Name (residence, business or office occupant). Example: Joe's Barbershop | `string()` |   | `true` |  
`emergency.postal_code` | Postal code. Example: 10027-0401 | `string()` |   | `true` |  
`emergency.region` | National subdivisions (state, region, province, prefecture). Example: New York | `string()` |   | `true` |  
`emergency.street` | Primary road or street. Example: Broadway | `string()` |   | `true` |  
`emergency.street_direction` | Leading street direction. Example: N, W | `string()` |   | `false` |  
`emergency.street_suffix` | Trailing street suffix. Example: SW | `string()` |   | `false` |  
`emergency.street_type` | Street type. Example: Avenue, Platz, Street | `string()` |   | `false` |  
`emergency` | Emergency address | `object()` |   | `false` |  



## Fetch

> GET /v2/accounts/{ACCOUNT_ID}/addresses

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/addresses
```

## Create

> PUT /v2/accounts/{ACCOUNT_ID}/addresses

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/addresses
```

## Fetch

> GET /v2/accounts/{ACCOUNT_ID}/addresses/{ADDRESS_ID}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/addresses/{ADDRESS_ID}
```

## Change

> POST /v2/accounts/{ACCOUNT_ID}/addresses/{ADDRESS_ID}

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/addresses/{ADDRESS_ID}
```

## Patch

> PATCH /v2/accounts/{ACCOUNT_ID}/addresses/{ADDRESS_ID}

```shell
curl -v -X PATCH \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/addresses/{ADDRESS_ID}
```

## Remove

> DELETE /v2/accounts/{ACCOUNT_ID}/addresses/{ADDRESS_ID}

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/addresses/{ADDRESS_ID}
```

