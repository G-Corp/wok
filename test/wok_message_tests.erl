-module(wok_message_tests).
-include_lib("eunit/include/eunit.hrl").
-include("../include/wok_message_handler.hrl").

wok_message_tests_test_() ->
  {setup,
   fun() ->
       meck:new(doteki),
       meck:expect(doteki, get_env, 2, test_handler),
       meck:new(test_handler, [non_strict]),
       meck:expect(test_handler, parse, fun(V) ->
                                            {ok,
                                             #msg{
                                                uuid = <<"UUID">>,
                                                from = <<"from">>,
                                                to = <<"to">>,
                                                body = <<"[", V/binary, "]">>},
                                             <<>>}
                                        end),
       meck:new(wok_state),
       meck:expect(wok_state, state, 0, global_state)
   end,
   fun(_) ->
       meck:unload(wok_state),
       meck:unload(test_handler),
       meck:unload(doteki)
   end,
   [
    fun() ->
        ?assertMatch({ok, #wok_message{
                             request = #msg{
                                          uuid = <<"UUID">>,
                                          from = <<"from">>,
                                          to = <<"to">>,
                                          body = <<"[message]">>,
                                          offset = 1,
                                          key = <<"key">>,
                                          message = <<"message">>,
                                          topic = <<"topic">>,
                                          partition = 0}}},
                     wok_message:new(<<"topic">>, 0, 1, <<"key">>, <<"message">>))
    end,
    fun() ->
        ?assertMatch(#wok_message{
                        request = #msg{
                                     from = <<"from">>,
                                     to = <<"to">>,
                                     headers = headers,
                                     message = <<"message">>,
                                     uuid = <<"UUID">>}},
                     wok_message:new_req(<<"from">>, <<"to">>, headers, <<"message">>, <<"UUID">>))
    end,
    fun() ->
        ?assertMatch(#wok_message{
                        request = #msg{
                                     params = test}},
                     wok_message:set_params(#wok_message{}, test))
    end,
    fun() ->
        ?assertMatch(#wok_message{
                        action = {module, function}},
                     wok_message:set_action(#wok_message{}, {module, function}))
    end,
    fun() ->
        ?assertMatch(#wok_message{
                        request = #msg{to = <<"to">>}},
                     wok_message:set_to(#wok_message{}, <<"to">>))
    end,
    fun() ->
        ?assertMatch(#wok_message{
                        global_state = global_state},
                     wok_message:set_global_state(#wok_message{}))
    end,
    fun() ->
        ?assertMatch(#wok_message{
                        local_state = local_state},
                     wok_message:set_local_state(#wok_message{}, local_state))
    end,
    fun() ->
        ?assertMatch(local_state,
                     wok_message:get_local_state(#wok_message{
                                                    local_state = local_state}))
    end,
    fun() ->
        ?assertMatch(noreply,
                     wok_message:get_response(#wok_message{
                                                 reply = false})),
        ?assertMatch({reply, <<"topic">>, <<"from">>, <<"to">>, <<"body">>},
                     wok_message:get_response(#wok_message{
                                                 reply = true,
                                                 response = #msg{
                                                               topic = <<"topic">>,
                                                               from = <<"from">>,
                                                               to = <<"to">>,
                                                               body = <<"body">>}})),
        ?assertMatch({reply, {<<"topic">>, 1}, <<"from">>, <<"to">>, <<"body">>},
                     wok_message:get_response(#wok_message{
                                                 reply = true,
                                                 response = #msg{
                                                               topic = <<"topic">>,
                                                               partition = 1,
                                                               from = <<"from">>,
                                                               to = <<"to">>,
                                                               body = <<"body">>}}))
    end,
    fun() ->
        ?assertMatch(#{uuid := <<"UUID">>,
                       from := <<"from">>,
                       to := <<"to">>,
                       headers := [],
                       body := <<"body">>,
                       params := #{}},
                     wok_message:content(#wok_message{
                                            request = #msg{
                                                         uuid = <<"UUID">>,
                                                         from = <<"from">>,
                                                         to = <<"to">>,
                                                         headers = [],
                                                         body = <<"body">>,
                                                         params = #{}}}))
    end,
    fun() ->
        ?assertMatch(<<"UUID">>,
                     wok_message:uuid(#wok_message{
                                         request = #msg{
                                                      uuid = <<"UUID">>}}))
    end,
    fun() ->
        ?assertMatch(<<"from">>,
                     wok_message:from(#wok_message{
                                         request = #msg{
                                                      from = <<"from">>}}))
    end,
    fun() ->
        ?assertMatch(<<"to">>,
                     wok_message:to(#wok_message{
                                       request = #msg{
                                                    to = <<"to">>}}))
    end,
    fun() ->
        ?assertMatch([],
                     wok_message:headers(#wok_message{
                                            request = #msg{
                                                         headers = []}}))
    end,
    fun() ->
        ?assertMatch(<<"body">>,
                     wok_message:body(#wok_message{
                                         request = #msg{
                                                      body = <<"body">>}}))
    end,
    fun() ->
        ?assertMatch(#wok_message{
                        request = #msg{
                                     body = <<"newbody">>}},
                     wok_message:body(#wok_message{
                                         request = #msg{
                                                      body = <<"body">>}},
                                      <<"newbody">>))
    end,
    fun() ->
        ?assertMatch(<<"topic">>,
                     wok_message:topic(#wok_message{
                                          request = #msg{
                                                       topic = <<"topic">>}}))
    end,
    fun() ->
        ?assertMatch(0,
                     wok_message:partition(#wok_message{
                                              request = #msg{
                                                           partition = 0}}))
    end,
    fun() ->
        ?assertMatch(#{<<"a">> := <<"1">>,
                       <<"b">> := <<"2">>},
                     wok_message:params(#wok_message{
                                           request = #msg{
                                                        params = #{<<"a">> => <<"1">>,
                                                                   <<"b">> => <<"2">>}}}))
    end,
    fun() ->
        ?assertMatch(global_state,
                     wok_message:global_state(#wok_message{
                                                 global_state = global_state}))
    end,
    fun() ->
        ?assertMatch(local_state,
                     wok_message:local_state(#wok_message{
                                                local_state = local_state}))
    end,
    fun() ->
        ?assertMatch(#{key1 := value1,
                       key2 := value2},
                     wok_message:custom_data(#wok_message{
                                                custom_data = #{key1 => value1,
                                                                key2 => value2}}))
    end,
    fun() ->
        ?assertMatch(value1,
                     wok_message:custom_data(#wok_message{
                                                custom_data = #{key1 => value1,
                                                                key2 => value2}},
                                             key1))

    end,
    fun() ->
        ?assertMatch({ok, #wok_message{
                             custom_data = #{key1 := value1,
                                             key2 := value2,
                                             key3 := value3}}},
                     wok_message:custom_data(#wok_message{
                                                custom_data = #{key1 => value1,
                                                                key2 => value2}},
                                             key3, value3))

    end,
    fun() ->
        ?assertMatch({ok, value2,
                      #wok_message{
                         custom_data = #{key1 := value1,
                                         key2 := new_value2}}},
                     wok_message:custom_data(#wok_message{
                                                custom_data = #{key1 => value1,
                                                                key2 => value2}},
                                             key2, new_value2))

    end,
    fun() ->
        ?assertMatch(#{from := <<"from">>,
                       to := <<"to">>,
                       body := <<"body">>},
                     wok_message:response(#wok_message{
                                             response = #msg{
                                                           from = <<"from">>,
                                                           to = <<"to">>,
                                                           body = <<"body">>}}))
    end,
    fun() ->
        ?assertMatch(<<"from">>,
                     wok_message:response_from(#wok_message{
                                                  response = #msg{
                                                                from = <<"from">>}}))
    end,
    fun() ->
        ?assertMatch(<<"to">>,
                     wok_message:response_to(#wok_message{
                                                response = #msg{
                                                              to = <<"to">>}}))
    end,
    fun() ->
        ?assertMatch(<<"body">>,
                     wok_message:response_body(#wok_message{
                                                  response = #msg{
                                                                body = <<"body">>}}))
    end,
    fun() ->
        ?assertMatch(#wok_message{
                        response = #msg{
                                      body = <<"newbody">>}},
                     wok_message:response_body(#wok_message{
                                                  response = #msg{
                                                                body = <<"body">>}},
                                               <<"newbody">>))
    end,
    fun() ->
        ?assertMatch(#wok_message{reply = false},
                     wok_message:noreply(#wok_message{}))
    end,
    fun() ->
        ?assertMatch(#wok_message{
                        reply = true,
                        response = #msg{
                                      from = <<"from">>,
                                      to = <<"to">>,
                                      body = <<"body">>,
                                      topic = <<"topic">>,
                                      partition = 1}},
                     wok_message:reply(#wok_message{},
                                       {<<"topic">>, 1},
                                       <<"from">>,
                                       <<"to">>,
                                       <<"body">>))
    end,
    fun() ->
        ?assertMatch(#wok_message{
                        reply = true,
                        response = #msg{
                                      from = <<"from">>,
                                      to = <<"to">>,
                                      body = <<"body">>,
                                      topic = <<"topic">>,
                                      partition = undefined}},
                     wok_message:reply(#wok_message{},
                                       <<"topic">>,
                                       <<"from">>,
                                       <<"to">>,
                                       <<"body">>))
    end,
    fun() ->
        ?assertMatch(#wok_message{
                        reply = true,
                        request = #msg{to = <<"me">>},
                        response = #msg{
                                      from = <<"me">>,
                                      to = <<"to">>,
                                      body = <<"body">>,
                                      topic = <<"topic">>,
                                      partition = 1}},
                     wok_message:reply(#wok_message{
                                         request = #msg{to = <<"me">>}},
                                       {<<"topic">>, 1},
                                       <<"to">>,
                                       <<"body">>))
    end,
    fun() ->
        ?assertMatch(#wok_message{
                        reply = true,
                        request = #msg{to = <<"me">>},
                        response = #msg{
                                      from = <<"me">>,
                                      to = <<"to">>,
                                      body = <<"body">>,
                                      topic = <<"topic">>,
                                      partition = undefined}},
                     wok_message:reply(#wok_message{
                                          request = #msg{to = <<"me">>}},
                                       <<"topic">>,
                                       <<"to">>,
                                       <<"body">>))
    end
   ]}.
