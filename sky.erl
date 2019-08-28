-module(sky).

-compile(export_all).

consume_api(MyLong, MyLat) ->
    Url =
	io_lib:format("https://opensky-network.org/api/states/all?la"
		      "min=~.4f&lomin=~.4f&lamax=~.4f&lomax=~.4f",
		      [4.58389e+1, 5.99619999999999997442,
		       4.78228999999999970782e+1, 1.05226e+1]),
    {ok, RequestId} = httpc:request(get, {Url, []}, [],
				    [{sync, false}]),
    receive
      {http, {RequestId, Result}} ->
	  get_list(Result, MyLong, MyLat)
      after 100000 -> error
    end.

get_list({_, _, Body}, MyLong, MyLat) ->
    {_, [_ | T]} = mochijson2:decode(Body),
    [{_, L}] = T,
    find(L, MyLong, MyLat).

find([H | T], MyLong, MyLat) ->
    Long2 = lists:nth(6, H),
    Lat2 = lists:nth(7, H),
    helper(T, {[], distance(MyLong, MyLat, Long2, Lat2)},
	   MyLong, MyLat).

helper([], {CPlane, Dist}, _, _) ->
    {Dist, lists:nth(2, CPlane), lists:nth(6, CPlane),
     lists:nth(7, CPlane), lists:nth(3, CPlane),
     lists:nth(4, CPlane)};
helper([H | T], {CPlane, Dist}, MyLong, MyLat) ->
    Long2 = lists:nth(6, H),
    Lat2 = lists:nth(7, H),
    NewDist = distance(MyLong, MyLat, Long2, Lat2),
    OldDist = Dist,
    if NewDist > OldDist ->
	   helper(T, {CPlane, OldDist}, MyLong, MyLat);
       true -> helper(T, {H, NewDist}, MyLong, MyLat)
    end.

% Not Mine
distance(Lat1, Long1, Lat2, Long2) ->
    V = math:pi() / 180,
    R = 6.3728e+3,    % In kilometers
    Diff_Lat = (Lat2 - Lat1) * V,
    Diff_Long = (Long2 - Long1) * V,
    NLat = Lat1 * V,
    NLong = Lat2 * V,
    A = math:sin(Diff_Lat / 2) * math:sin(Diff_Lat / 2) +
	  math:sin(Diff_Long / 2) * math:sin(Diff_Long / 2) *
	    math:cos(NLat)
	    * math:cos(NLong),
    C = 2 * math:asin(math:sqrt(A)),
    R * C.
