-module(wok_middlewares_message_tests).

-include_lib("eunit/include/eunit.hrl").

meck_middleware_one() ->
  meck:new(fake_middleware_one, [non_strict]),
  meck:expect(fake_middleware_one, init,
              fun(X) ->
                  {ok, X}
              end),
  meck:expect(fake_middleware_one, incoming_message,
              fun(M, S) ->
                  {ok, M + 1, S}
              end),
  meck:expect(fake_middleware_one, outgoing_message,
              fun(M, S) ->
                  {ok, M + 2, S}
              end).

unmeck_middleware_one() ->
  meck:unload(fake_middleware_one).

meck_middleware_two() ->
  meck:new(fake_middleware_two, [non_strict]),
  meck:expect(fake_middleware_two, init,
              fun(X) ->
                  {ok, X}
              end),
  meck:expect(fake_middleware_two, incoming_message,
              fun(M, S) ->
                  {ok, M * 2, S}
              end),
  meck:expect(fake_middleware_two, outgoing_message,
              fun(M, S) ->
                  {ok, M * 3, S}
              end).

unmeck_middleware_two() ->
  meck:unload(fake_middleware_two).

meck_middleware_three() ->
  meck:new(fake_middleware_three, [non_strict]),
  meck:expect(fake_middleware_three, init,
              fun(X) ->
                  {ok, X}
              end),
  meck:expect(fake_middleware_three, incoming_message,
              fun(_, S) ->
                  {stop, test, S}
              end),
  meck:expect(fake_middleware_three, outgoing_message,
              fun(_, S) ->
                  {stop, test, S}
              end).

unmeck_middleware_three() ->
  meck:unload(fake_middleware_three).

meck_middleware_four() ->
  meck:new(fake_middleware_four, [non_strict]).

unmeck_middleware_four() ->
  meck:unload(fake_middleware_four).

%% Tests

wok_middelware_no_middleware_test_() ->
  {setup,
   fun() ->
       meck_middleware_one(),
       ok = doteki:set_env_from_config([{wok, [{middlewares, []}]}]),
       wok_middlewares:start_link()
   end,
   fun
     ({ok, _}) ->
       wok_middlewares:stop(),
       unmeck_middleware_one();
     (_) ->
       unmeck_middleware_one()
   end,
   fun(R) ->
       {with, R,
        [fun(X) -> ?assertMatch({ok, _}, X) end,
         fun(_) -> ?assertMatch(nostate, wok_middlewares:state(fake_middleware_one)) end,
         fun(_) -> ?assertMatch({ok, message}, wok_middlewares:incoming_message(message)) end,
         fun(_) -> ?assertMatch({ok, message}, wok_middlewares:outgoing_message(message)) end]
       }
   end}.

wok_middelware_inout_one_test_() ->
  {setup,
   fun() ->
       meck_middleware_one(),
       ok = doteki:set_env_from_config([{wok,
                                         [{middlewares,
                                           [
                                            {fake_middleware_one, []}
                                           ]
                                          }]
                                        }]),
       wok_middlewares:start_link()
   end,
   fun
     ({ok, _}) ->
       wok_middlewares:stop(),
       unmeck_middleware_one();
     (_) ->
       unmeck_middleware_one()
   end,
   fun(R) ->
       {with, R,
        [fun(X) -> ?assertMatch({ok, _}, X) end,
         fun(_) -> ?assertMatch(nostate, wok_middlewares:state(fake_middleware_one)) end,
         fun(_) -> ?assertMatch({ok, 2}, wok_middlewares:incoming_message(1)) end,
         fun(_) -> ?assertMatch({ok, 3}, wok_middlewares:outgoing_message(1)) end]
       }
   end}.

wok_middelware_inout_one_and_two_test_() ->
  {setup,
   fun() ->
       meck_middleware_one(),
       meck_middleware_two(),
       ok = doteki:set_env_from_config([{wok,
                                         [{middlewares,
                                           [
                                            {fake_middleware_one, []},
                                            {fake_middleware_two, []}
                                           ]
                                          }]
                                        }]),
       wok_middlewares:start_link()
   end,
   fun
     ({ok, _}) ->
       wok_middlewares:stop(),
       unmeck_middleware_one(),
       unmeck_middleware_two();
     (_) ->
       unmeck_middleware_one(),
       unmeck_middleware_two()
   end,
   fun(R) ->
       {with, R,
        [fun(X) -> ?assertMatch({ok, _}, X) end,
         fun(_) -> ?assertMatch(nostate, wok_middlewares:state(fake_middleware_one)) end,
         fun(_) -> ?assertMatch(nostate, wok_middlewares:state(fake_middleware_two)) end,
         fun(_) -> ?assertMatch({ok, 4}, wok_middlewares:incoming_message(1)) end,
         fun(_) -> ?assertMatch({ok, 5}, wok_middlewares:outgoing_message(1)) end]
       }
   end}.

wok_middelware_inout_stop_test_() ->
  {setup,
   fun() ->
       meck_middleware_one(),
       meck_middleware_three(),
       ok = doteki:set_env_from_config([{wok,
                                         [{middlewares,
                                           [
                                            {fake_middleware_three, []},
                                            {fake_middleware_one, []}
                                           ]
                                          }]
                                        }]),
       wok_middlewares:start_link()
   end,
   fun
     ({ok, _}) ->
       wok_middlewares:stop(),
       unmeck_middleware_one(),
       unmeck_middleware_three();
     (_) ->
       unmeck_middleware_one(),
       unmeck_middleware_three()
   end,
   fun(R) ->
       {with, R,
        [fun(X) -> ?assertMatch({ok, _}, X) end,
         fun(_) -> ?assertMatch(nostate, wok_middlewares:state(fake_middleware_one)) end,
         fun(_) -> ?assertMatch(nostate, wok_middlewares:state(fake_middleware_three)) end,
         fun(_) -> ?assertMatch({stop, fake_middleware_three, test}, wok_middlewares:incoming_message(1)) end,
         fun(_) -> ?assertMatch({stop, fake_middleware_three, test}, wok_middlewares:outgoing_message(1)) end]
       }
   end}.

wok_middelware_with_missing_methods_test_() ->
  {setup,
   fun() ->
       meck_middleware_four(),
       ok = doteki:set_env_from_config([{wok,
                                         [{middlewares,
                                           [
                                            {fake_middleware_four, []}
                                           ]
                                          }]
                                        }]),
       wok_middlewares:start_link()
   end,
   fun
     ({ok, _}) ->
       wok_middlewares:stop(),
       unmeck_middleware_four();
     (_) ->
       unmeck_middleware_four()
   end,
   fun(R) ->
       {with, R,
        [fun(X) -> ?assertMatch({ok, _}, X) end,
         fun(_) -> ?assertMatch(nostate, wok_middlewares:state(fake_middleware_four)) end,
         fun(_) -> ?assertMatch({ok, 1}, wok_middlewares:incoming_message(1)) end,
         fun(_) -> ?assertMatch({ok, 1}, wok_middlewares:outgoing_message(1)) end]
       }
   end}.
