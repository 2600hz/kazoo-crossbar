#!/usr/bin/env escript
%%! +A0
%% -*- coding: utf-8 -*-

-mode(compile).
-export([main/1]).

-define(OUT, "priv/couchdb/schemas/timezone.json").
-define(IN, ?OUT ++ ".src").
-define(AUTOGEN_REPLACE, <<"\"enum\": [],">>).
-define(PRETTY_SPACE, "        ").

main(Opts) ->
    maybe_create_timezones(lists:member("--force", Opts)).

maybe_create_timezones(true) ->
    create_timezones();
maybe_create_timezones(false) ->
    case filelib:is_regular(?OUT) of
        true -> ok;
        false -> create_timezones()
    end.

create_timezones() ->
    {'ok', SchemaBin} = file:read_file(?IN),
    Timezones = timezones(),
    NewSchema = binary:replace(SchemaBin, ?AUTOGEN_REPLACE, <<"\"enum\": [\n", Timezones/binary, "\n    ],">>),
    'ok' = file:write_file(?OUT, NewSchema).

timezones() ->
    Bin = read_tz_database_hrl(),
    [Tz | Tzs] = lists:usort(lists:foldl(fun match_tz/2
                                        ,[]
                                        ,binary:split(Bin, <<"\n">>, [global, trim_all]))
                            ),
    iolist_to_binary([<<?PRETTY_SPACE, $", Tz/binary, $">>] ++ [<<$,, $\n, ?PRETTY_SPACE, $", B/binary, $">> || B <- Tzs]).

match_tz(Line, Acc) ->
    Opts = [global, {capture, [1], binary}],
    case re:run(Line, "^\\s*\\{\"([^\"]+).*$", Opts) of
        {match, [Captured]} -> Acc ++ Captured;
        _ -> Acc
    end.

read_tz_database_hrl() ->
    RootDir = filename:absname(filename:join([filename:dirname(escript:script_name()), "..", "..", ".."])),
    case file:read_file(filename:join([RootDir, "_build", "default", "lib", "qdate_localtime", "include", "tz_database.hrl"])) of
        {ok, Bin} ->
            Bin;
        {error, noent} ->
            case file:read_file(filename:join([RootDir, "deps", "qdate_localtime", "include", "tz_database.hrl"])) of
                {ok, Bin} ->
                    Bin;
                {error, noent}=Error ->
                    io:format("Error, unable to find qdate_localtime/include/tz_database.hrl, have you fetched deps?~n"),
                    throw({qdate_timezones, Error});
                Error ->
                    io:format("Error, unable to read deps/qdate_localtime/include/tz_database.hrl:~n~p~n"
                             ,[Error]
                             ),
                    throw(Error)
            end;
        Error ->
            io:format("Error, unable to read deps/qdate_localtime/include/tz_database.hrl:~n~p~n"
                     ,[Error]
                     ),
            throw(Error)
    end.
