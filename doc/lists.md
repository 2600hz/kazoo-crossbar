# Lists

Lists API offers a new way to save contacts.

Through the entries associated with a list, you can generate the behavior of a series of contacts which can be accessed by users who have different permissions or ownership over the entries.

#### Schema

Schema for a match list



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`description` | A friendly list description | `string(1..128)` |   | `false` |  
`name` | A friendly match list name | `string(1..128)` |   | `true` |  
`org` | Full legal name of the organization | `string()` |   | `false` |  
`owner_id` | UserId owner of the list | `string()` |   | `false` |  



#### Fetch

> GET /v2/accounts/{ACCOUNT_ID}/lists

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists
```


#### Fetch lists by User Id

> GET /v2/accounts/{ACCOUNT_ID}/users/{USER_ID}/lists

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/users/{USER_ID}/lists
```


#### Add new list (beware: no entries)

> PUT /v2/accounts/{ACCOUNT_ID}/lists

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data": {"name": "list name"}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists
```

#### Add new list which has an owner (beware: no entries)

> PUT /v2/accounts/{ACCOUNT_ID}/users/{USER_ID}/lists

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data": {"name": "list name"}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/users/{USER_ID}/lists
```

#### Delete list and its entries

This method can only be executed by an admin or by the owner of the lists, remember that the entries associated with the list will also be deleted

> DELETE /v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}
```

> DELETE /v2/accounts/{ACCOUNT_ID}/lists/users/{USER_ID}/{LIST_ID}

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/users/{USER_ID}/lists/{LIST_ID}
```

#### Get list properties (doesn't return entries)

If you want to get a list with an owner id the list needs to belong to the USER_ID or be triggered by an admin user

> GET /v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}
```

> GET /v2/accounts/{ACCOUNT_ID}/users/{USER_ID}/lists/{LIST_ID}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/users/{USER_ID}/lists/{LIST_ID}
```


#### Updating list (without entries)

If you want to update a list with an owner id the list needs to belong to the USER_ID or be triggered by an admin user

> PATCH /v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}

```shell
curl -v -X PATCH \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data": {"description": "desc"}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}
```

> PATCH /v2/accounts/{ACCOUNT_ID}/users/{USER_ID}/lists/{LIST_ID}

```shell
curl -v -X PATCH \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data": {"description": "desc"}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/users/{USER_ID}/lists/{LIST_ID}
```

#### Rewrite list

If you want to rewrite a list with an owner id the list needs to belong to the USER_ID or be triggered by an admin user

> POST /v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data": {"name": "New List name"}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}
```

> POST /v2/accounts/{ACCOUNT_ID}/users/{USER_ID}/lists/{LIST_ID}

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data": {"name": "New List name"}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/users/{USER_ID}/lists/{LIST_ID}
```

### List Entries

Schema for list entries



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`contacts.contact` | The phone number or email associated with the contact | `string(1..128)` |   | `true` |  
`contacts.contact_type` | The type of contact this is" | `string('phone_number' | 'email' | 'sms')` |   | `true` |  
`conacts.default` |If this is the default for this contact type | `boolean` |   | `false` |  
`conacts.description` |The description of the contact | `string(1..128)` |   | `false` |  
`description` | A description of the list entity | `string()` |   | `false` |  
`history.contact.contact` | The contact that was used | `object()` |   | `false` |   
`history.notes` | Notes from the communication | `string()` |   | `false` |  
`list_id` | The document id of the list document this list entry belongs to | `string()` |   | `false` |  
`name` | The name of the list entity | `string()` |   | `false` |  
`organization` | The organization this entity belongs to | `string()` |   | `false` |  



**If you want to access an entry and the list has an owner id, the user must be an admin or owner of that list**

#### Delete all entries from list

> DELETE /v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries
```

#### Get list entries

> GET /v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries
```


#### Add an entry to a list

> PUT /v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data": {"number": "0123", "displayname" : "List Entry"}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries
```


#### Delete entry from the list

> DELETE /v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries/{LIST_ENTRY_ID}

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries/{LIST_ENTRY_ID}
```


#### List entry properties

> GET /v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries/{LIST_ENTRY_ID}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries/{LIST_ENTRY_ID}
```


#### Update list entry

> PATCH /v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries/{LIST_ENTRY_ID}

```shell
curl -v -X PATCH \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data": {"firstname" : "First name"}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries/{LIST_ENTRY_ID}
```

#### Replace list entry

> POST /v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries/{LIST_ENTRY_ID}

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    -d '{"data": {"number": "0123", "displayname" : "New List Entry"}}' \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries/{LIST_ENTRY_ID}
```


#### Add photo to List entry

> POST /v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries/{LIST_ENTRY_ID}/photo

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries/{LIST_ENTRY_ID}/photo
```


#### List entry vcard

> GET /v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries/{LIST_ENTRY_ID}/vcard

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/lists/{LIST_ID}/entries/{LIST_ENTRY_ID}/vcard
```
