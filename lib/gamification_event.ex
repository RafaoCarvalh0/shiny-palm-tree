defmodule GamificationEvent do
  @moduledoc """
  This module is responsible for creating a user gamification event through the
  `create_user_gamification_event/1` function.

  The event is validated and then stored in memory using `ETS`(erlang term storage).

  The rules for the creation of the event are:

  - For an event to be valid, the raw data must follow the format:
  ```json
  {
    "event": <"amount_received" | "amount_requested">,
    "user_id": <integer>,
    "amount": <integer>,
    "created_at": <ISO 8601 string>
  }
  ```
  - When requesting an amount, the user must have enough balance to cover the requested amount.
  - The amount requested must be less than 1000.
  - The amount received must be less than 5000.
  - The event "amount_requested" can only be called 3 times per minute.
  """
  alias GamificationEventParser
  alias GamificationEventStore

  @required_fields ~w(event user_id amount created_at)a
  @amount_received_limit 5000
  @amount_requested_limit 1000
  @amount_requested_per_minute_limit 3

  @spec create_user_gamification_event(String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def create_user_gamification_event(raw_data) do
    with {:ok, event_map} <- GamificationEventParser.convert_raw_data_to_event_map(raw_data),
         {:ok, _} <- validate_required_fields(event_map),
         {:ok, _} <- validate_event(event_map),
         {:ok, user_data} <- publish_user_event(event_map) do
      {:ok, user_data}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp validate_required_fields(event_map) do
    if Enum.all?(@required_fields, &Map.has_key?(event_map, &1)) do
      {:ok, :valid}
    else
      {:error, "{\"error\": \"missing_required_fields\"}"}
    end
  end

  defp validate_event(%{event: "amount_received", amount: amount_received} = _event_map) do
    cond do
      amount_received < 0 ->
        {:error, "{\"error\": \"amount_received_cannot_be_negative\"}"}

      amount_received > @amount_received_limit ->
        {:error, "{\"error\": \"amount_received_exceeded_limit\"}"}

      true ->
        {:ok, :valid}
    end
  end

  defp validate_event(%{event: "amount_requested", amount: amount_requested} = event_map) do
    user_data = GamificationEventStore.get_user_balance_by_id(event_map.user_id)

    cond do
      amount_requested < 0 ->
        {:error, "{\"error\": \"amount_requested_cannot_be_negative\"}"}

      amount_requested > @amount_requested_limit ->
        {:error, "{\"error\": \"amount_requested_exceeded_limit\"}"}

      user_does_not_have_enough_funds?(user_data, amount_requested) ->
        {:error, "{\"error\": \"user_has_insufficient_funds\"}"}

      user_exceeded_amount_requested_per_minute?(event_map) ->
        {:error, "{\"error\": \"user_amount_requested_per_minute_limit_exceeded\"}"}

      true ->
        {:ok, :valid}
    end
  end

  defp validate_event(_event_map) do
    {:error, "{\"error\": \"invalid_event\"}"}
  end

  defp user_exceeded_amount_requested_per_minute?(event_map) do
    until_date = DateTime.utc_now()

    since_date = DateTime.shift(until_date, minute: -1)

    event_map
    |> Map.get(:user_id)
    |> GamificationEventStore.get_user_gamification_events_between_dates(
      "amount_requested",
      since_date,
      until_date
    )
    |> Enum.count() > @amount_requested_per_minute_limit
  end

  defp user_does_not_have_enough_funds?(nil, _amount_to_subtract), do: true

  defp user_does_not_have_enough_funds?(user_data, amount_to_subtract) do
    user_data.coins_balance - amount_to_subtract < 0
  end

  defp publish_user_event(%{event: "amount_received"} = event_map) do
    event_map
    |> insert_or_update_user_coins_balance()
    |> tap(fn _ -> GamificationEventStore.insert_user_gamification_event(event_map) end)
    |> format_response()
  end

  defp publish_user_event(%{event: "amount_requested"} = event_map) do
    event_map
    |> subtract_user_coins_balance()
    |> tap(fn _ -> GamificationEventStore.insert_user_gamification_event(event_map) end)
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
    event_map
    |> Map.put(:amount, event_map.amount * -1)
    |> insert_or_update_user_coins_balance()
  end

  defp format_response({:error, _} = error), do: error

  defp format_response(user_data) do
    {:ok, "{\"user_id\": #{user_data.user_id}, \"coins_balance\": #{user_data.coins_balance}}"}
  end
end
