defmodule GamificationEvent do
  alias GamificationEventParser
  alias GamificationEventStore

  @required_fields ~w(event user_id amount created_at)a
  @amount_received_limit 5000
  @amount_requested_limit 1000

  def init() do
    "Provide the user gamification event\n> "
    |> IO.gets()
    |> GamificationEvent.create_user_gamification_event()
    |> init()
  end

  defp init(_), do: init()

  def create_user_gamification_event(raw_data) do
    with {:ok, event_map} <- GamificationEventParser.convert_raw_data_to_event_map(raw_data),
         {:ok, _} <- validate_required_fields(event_map),
         {:ok, _} <- validate_event(event_map),
         {:ok, response} <-
           publish_user_event(event_map) do
      response
      |> inspect()
      |> IO.puts()
    else
      {:error, error} ->
        error
        |> inspect()
        |> IO.puts()
    end
  end

  defp validate_required_fields(event_map) do
    if Enum.all?(Map.keys(event_map), &(&1 in @required_fields)) do
      {:ok, :valid}
    else
      {:error, "{\"error\": \"missing_required_fields\"}"}
    end
  end

  defp validate_event(%{event: "amount_received", amount: amount_received} = _event_map) do
    if amount_received > @amount_received_limit do
      {:error, "{\"error\": \"amount_received_exceeded_limit\"}"}
    else
      {:ok, :valid}
    end
  end

  defp validate_event(%{event: "amount_requested", amount: amount_requested} = _event_map) do
    if amount_requested > @amount_requested_limit do
      {:error, "{\"error\": \"amount_requested_exceeded_limit\"}"}
    else
      {:ok, :valid}
    end
  end

  defp publish_user_event(%{event: "amount_received"} = event_map) do
    event_map
    |> insert_or_update_user_coins_balance()
    |> format_response()
  end

  defp publish_user_event(%{event: "amount_requested"} = event_map) do
    event_map
    |> subtract_user_coins_balance()
    |> format_response()
  end

  defp publish_user_event(_) do
    {:error, "{\"error\": \"invalid_event\"}"}
  end

  defp insert_or_update_user_coins_balance(event_map) do
    case GamificationEventStore.get_user_balance_by_id(event_map.user_id) do
      nil ->
        GamificationEventStore.insert_or_update_user_balance(event_map.user_id, event_map.amount)

      user_gamification_data ->
        new_user_balance = user_gamification_data.coins_balance + event_map.amount

        GamificationEventStore.insert_or_update_user_balance(event_map.user_id, new_user_balance)
    end
  end

  defp subtract_user_coins_balance(event_map) do
    user_data = GamificationEventStore.get_user_balance_by_id(event_map.user_id)

    if user_data && user_has_enough_funds?(user_data, event_map.amount) do
      event_map
      |> Map.put(:amount, event_map.amount * -1)
      |> insert_or_update_user_coins_balance()
    else
      {:error, "{\"error\": \"user_has_insufficient_funds\"}"}
    end
  end

  defp user_has_enough_funds?(user_data, amount_to_subtract) do
    user_data.coins_balance - amount_to_subtract >= 0
  end

  defp format_response({:error, _} = error), do: error

  defp format_response(user_data) do
    {:ok, "{\"user_id\": #{user_data.user_id}, \"coins_balance\": #{user_data.coins_balance}}"}
  end
end

GamificationEvent.init()
