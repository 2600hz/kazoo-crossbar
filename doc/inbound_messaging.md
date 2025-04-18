# Inbound Messaging

Currently an internal-only api for inbound s/mms hooks from Trunking IO.

Supports only `PUT` to `/hooks/` at present.

## About Messaging

See [TIO API Docs](https://gitlab.com/oomaforbin/onsip/trunkingio-sms/-/blob/main/docs/api/messages.md?ref_type=heads) for expected schema.

## Schema




## Examples

> PUT /hooks/accounts/{ACCOUNT_ID}/messaging/{CARRIER}

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/messaging/{CARRIER}
```

## Internal

configure Trunking IO s/mms DIDs to send hooks to a URL in the form:
http://{SERVER}:8000/hooks/messaging/trunkingio

### Authentication

cb_messaging allows the carrier module to handle authentication. For TrunkingIO, this is
hmac validation relying on a shared secret.

### Payload creation

cb_messaging expects carrier modules to have a callback returning (mostly) valid `kapps_im`. At least these fields:
```
"From"
"To"
"Body"
"Route-Type"
"Event-Category"
```