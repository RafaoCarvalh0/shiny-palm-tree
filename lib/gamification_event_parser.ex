defmodule GamificationEventParser do
  @moduledoc """
  This module is responsible for parsing the raw JSON data into an event map.
  """
  @type event_map ::
          %{
            required(:event) => String.t(),
            required(:user_id) => non_neg_integer(),
            required(:amount) => integer(),
            required(:created_at) => NaiveDateTime.t()
          }

  @spec convert_raw_data_to_event_map(String.t()) :: {:ok, event_map()} | {:error, String.t()}
  def convert_raw_data_to_event_map(event) do
    event
    |> String.replace("\n", "")
    |> String.replace(~r/[{}\\"\s]/, "")
    |> String.split(",")
    |> Enum.map(&String.split(&1, ":"))
    |> Enum.reduce_while(%{}, fn [key | value], acc ->
      key
      |> String.to_atom()
      |> build_event_map(value, acc)
      |> case do
        {:error, error} ->
          {:halt, {:error, error}}

        {:ok, event_map} ->
          {:cont, event_map}
      end
    end)
    |> case do
      {:error, error} -> {:error, error}
      event_map -> {:ok, event_map}
    end
  end

  defp build_event_map(key, [value], event_map) when key == :event,
    do: {:ok, Map.put(event_map, key, to_string(value))}

  defp build_event_map(key, [value], event_map) when key in [:user_id, :amount],
    do: {:ok, Map.put(event_map, key, String.to_integer(value))}

  defp build_event_map(key, value, event_map) when key == :created_at do
    case NaiveDateTime.from_iso8601(Enum.join(value, ":")) do
      {:ok, naive_date_time} -> {:ok, Map.put(event_map, key, naive_date_time)}
      _ -> {:error, build_event_map_error()}
    end
  end

  defp build_event_map(_, _, _), do: {:error, build_event_map_error()}

  defp build_event_map_error(), do: "{\"error\": \"invalid_input\"}"
end
