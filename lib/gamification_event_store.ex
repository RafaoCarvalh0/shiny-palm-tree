defmodule GamificationEventStore do
  import EtsTables

  @type user_gamification_data :: %{user_id: non_neg_integer(), coins_balance: non_neg_integer()}

  @spec get_user_balance_by_id(non_neg_integer()) :: user_gamification_data() | nil
  def get_user_balance_by_id(user_id) do
    start()

    ets_user_gamification_data()
    |> :ets.lookup(user_id)
    |> format_ets_lookup_response()
  end

  defp format_ets_lookup_response([{_, user_gamification_data}]), do: user_gamification_data

  defp format_ets_lookup_response(_), do: nil

  @spec insert_or_update_user_balance(non_neg_integer(), non_neg_integer()) ::
          user_gamification_data() | nil
  def insert_or_update_user_balance(user_id, new_coins_balance) do
    start()

    ets_attrs = {user_id, %{user_id: user_id, coins_balance: new_coins_balance}}

    :ets.insert(ets_user_gamification_data(), ets_attrs)

    get_user_balance_by_id(user_id)
  end

  @spec insert_user_gamification_event(GamificationEventParser.event_map()) :: boolean()
  def insert_user_gamification_event(event_map) do
    timestamp = DateTime.to_string(DateTime.utc_now())
    user_id = event_map.user_id

    ets_attrs = {timestamp, user_id, event_map}

    :ets.insert_new(ets_user_gamification_events(), ets_attrs)
  end

  def get_user_gamification_events_between_dates(user_id, event, utc_since_date, utc_until_date) do
    since_date = DateTime.to_string(utc_since_date)
    until_date = DateTime.to_string(utc_until_date)

    match_spec = [
      {{:"$1", user_id, :"$2"}, [{:==, {:map_get, :event, :"$2"}, event}],
       [{{:"$1", user_id, :"$2"}}]}
    ]

    ets_user_gamification_events()
    |> :ets.select(match_spec)
    |> Enum.filter(fn {timestamp, _, _} ->
      timestamp >= since_date and timestamp <= until_date
    end)
    |> Enum.map(fn {_, _, event_map} -> event_map end)
  end
end
