#!/usr/bin/env escript
%%! +A0
%% -*- coding: utf-8 -*-

%% Creates a list of deps to be served on HTTP requests to base
%% Crossbar address
%% e.g: curl http://crossbar.server:8000
%% will return the KAZOO ASCII art and the list of Erlang deps used

-mode(compile).
-export([main/1]).

main([DepsListTxt, DepsDirs]) ->
    maybe_dep_depies(DepsListTxt, DepsDirs, os:getenv("REBAR_DEPS_DIR") =:= false).

maybe_dep_depies(DepsListTxt, DepsDirs, true) ->
    dep_depies(DepsListTxt, DepsDirs);
maybe_dep_depies(DepsListTxt, _, false) ->
    case filelib:is_regular(DepsListTxt) of
        true ->
            ok;
        false ->
            dep_depies(DepsListTxt, rebar)
    end.

dep_depies(DepsListTxt, DepsDirs) ->
    {'ok', IODevice} = file:open(DepsListTxt, ['write']),
    Header = unicode:characters_to_binary(io_lib:format("KAZOO ~tss these Erlang dependencies: \n\n", [[129505]])),
    'ok' = file:write(IODevice, Header),

    TableHeader = io_lib:format("| ~-23s | ~s |~n", ["Dependency", "License"]),
    'ok' = file:write(IODevice, TableHeader),

    Deps = find_deps(DepsDirs),
    _ = lists:foreach(fun(Dep) -> find_dep_license(Dep, IODevice) end, Deps),
    'ok' = file:close(IODevice).

find_deps(rebar) ->
    RootDir = filename:absname(filename:join([filename:dirname(escript:script_name()), "..", "..", ".."])),
    RebarLibDir = os:getenv("REBAR_DEPS_DIR"),
    [_|_] = CoreApps = scna_apps(filename:join([RootDir, "core", "*"])),
    [_|_] = KApps = scna_apps(filename:join([RootDir, "applications", "*"])),
    [_|_] = RebarApps = scna_apps(filename:join(RebarLibDir, "*")),
    [filename:join(RebarLibDir, App) || App <- RebarApps -- lists:append(CoreApps, KApps)];
find_deps(DepsDirs) ->
    lists:usort(filelib:wildcard(filename:join([DepsDirs, "*"]))).

scna_apps(Wilcard) ->
    [App || Path <- filelib:wildcard(Wilcard),
            filelib:is_dir(Path),
            App <- [filename:basename(Path)],
            not badies(App)
    ].

badies("."++_) -> true;
badies("Makefile") -> true;
badies(_) -> false.

find_dep_license(DepDir, IODevice) ->
    DepName = filename:basename(DepDir),
    case find_license(DepDir) of
        'undefined' -> 'ok';
        License ->
            Line = io_lib:format("| ~-23s | ~s |~n", [DepName, License]),
            'ok' = file:write(IODevice, Line)
    end.

find_license(DepDir) ->
    LicenseFile = filename:join([DepDir, <<"LICENSE">>]),
    case filelib:is_regular(LicenseFile) of
        'false' -> 'undefined';
        'true' -> find_license_link(DepDir)
    end.

find_license_link(DepDir) ->
    find_license_link(DepDir, file:read_file(filename:join([DepDir, ".git", "config"]))).

find_license_link(DepDir, {'error', _E}) ->
    find_license_text(filename:join([DepDir, <<"LICENSE">>]));
find_license_link(DepDir, {'ok', Config}) ->
    {'match', [BaseURL]} = re:run(Config, <<"url = (.+)\n">>, [{'capture', 'all_but_first', 'binary'}]),

    case file:read_file(filename:join([DepDir, ".git", "HEAD"])) of
        {'ok', <<HEAD:40/binary>>} -> [BaseURL, "/blob/", HEAD, "/LICENSE"];
        {'ok', _SomethingElse} -> [BaseURL, "/blob/master/LICENSE"]
    end.

find_license_text(LicenseFile) ->
    {'ok', Contents} = file:read_file(LicenseFile),
    [Head | _] = binary:split(Contents, <<"\n\n">>),
    binary:replace(Head, <<"">>, <<>>).
