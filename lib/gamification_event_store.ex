defmodule GamificationEventStore do
  import EtsTables

  @type user_gamification_data :: %{user_id: non_neg_integer(), coins_balance: non_neg_integer()}

  @spec get_user_balance_by_id(non_neg_integer()) :: user_gamification_data() | nil
  def get_user_balance_by_id(user_id) do
    start()

    EtsTables.ets_user_gamification_data()
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

    :ets.insert(EtsTables.ets_user_gamification_data(), ets_attrs)

    get_user_balance_by_id(user_id)
  end
end
