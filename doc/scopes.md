# Scopes

## About Scopes

### Crossbar Binding
You can define a callback to enforce custom scopes in a crossbar module with the `allowed_scopes` binding.


```erlang
-spec init() -> 'ok'.
init() ->
    Bindings = [{<<"*.allowed_scopes.accounts">>, 'allowed_scopes'}
               , .... Other Bindings
               ],
    cb_modules_util:bind(?MODULE, Bindings).
```

#### Custom List
```erlang
%%------------------------------------------------------------------------------
%% @doc 
%% @end
%%------------------------------------------------------------------------------
-spec allowed_scopes() -> kz_term:ne_binaries().
allowed_scopes() ->   
  ?CB_DEFAULT_SCOPES.

-spec allowed_scopes(kz_term:ne_binary()) -> kz_term:ne_binaries().
allowed_scopes(AuthModule) ->
  lager:debug("fetching allowed scopes for ~p", [AuthModule]),
  kz_auth_scope:to_list(<<"crossbar:read_only">>).
```

#### Auth Module Config
```erlang
%%------------------------------------------------------------------------------
%% @doc 
%% @end
%%------------------------------------------------------------------------------
-spec allowed_scopes() -> kz_term:ne_binaries().
allowed_scopes() ->   
  ?CB_DEFAULT_SCOPES.

-spec allowed_scopes(kz_term:ne_binary()) -> kz_term:ne_binaries().
allowed_scopes(AuthModule) ->
  lager:debug("fetching allowed scopes for ~p", [AuthModule]),  
  crossbar_auth:available_scopes(AuthModule).
```

#### Schema

Kazoo Auth Scope Definition



Key | Description | Type | Default | Required | Support Level
--- | ----------- | ---- | ------- | -------- | -------------
`description` | Scope description | `string()` |   | `false` |  
`id` | Id of scope | `string()` |   | `true` |  
`name` | Name of scope | `string()` |   | `false` |  
`permissions.[]` |   | `string()` |   | `true` |  
`permissions` | Specifies who can request using this scope, values are '{ACCOUNT_TYPE}:{USER_TYPE_OR_STAR}. ACCOUNT_TYPE can be 'master', 'reseller', 'non-reseller'. USER_TYPE can be 'user', 'admin' or '*' as catch all | `array(string())` |   | `true` |  
`precedence` | Specifies which rules take precedence if scope matches both allow and deny rules | `string('allow' | 'deny')` | `allow` | `false` |  
`scopes.[]` |   | `string()` |   | `false` |  
`scopes` | List of subscopes | `array(string())` | `[]` | `false` |  



## Fetch

> GET /v2/scopes

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/scopes
```

## Create

> PUT /v2/scopes

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/scopes
```

## Fetch

> GET /v2/scopes/{SCOPE}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/scopes/{SCOPE}
```

## Change

> POST /v2/scopes/{SCOPE}

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/scopes/{SCOPE}
```

## Remove

> DELETE /v2/scopes/{SCOPE}

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/scopes/{SCOPE}
```

