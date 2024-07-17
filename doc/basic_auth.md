# Basic Auth

As an alternative for generated Tokens, you can authorize requests with [HTTP Basic Auth](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication#basic) using your account ID, user name and password.

## Sample cURL Requests

```shell
curl -v \
    --basic --user {AUTH_ACCOUNT_ID}:$PASSWORD \
    http://server.com:8000/v2/accounts/{ACCOUNT_ID}/devices
```

This is useful for reseller to execute requests against a their sub-account quickly.

**Basic Auth Username**

Should be set to `account_id` of the authorizing account.

**Basic Password Password**

Should be set to MD5 hash of your account's `username:password`

Example shell command to get the md5 sum of your `username:password`:

```shell
# the output of the echo command is 133e1b8eda335c4c7f7a508620ca7f10
PASSWORD=`echo -n username:password | md5sum | awk '{print $1}'`
```