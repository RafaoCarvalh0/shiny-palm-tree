defmodule StartHere do
  @moduledoc """
  This module is the entry point for the application.
  It provides a (very) simple interface for the user to interact with the application.

  If you wanna check it out, just run `iex -S mix` and then `StartHere.init()`.
  """
  alias GamificationEvent

  def init() do
    """

    ----------------------------------------------------------------
    Provide the user gamification event following this json format:
    {"event": <"amount_received" | "amount_requested">, "user_id": <integer>, "amount": <integer>, "created_at": <ISO 8601 string>}
    ----------------------------------------------------------------

    """
    |> IO.gets()
    |> GamificationEvent.create_user_gamification_event()
    |> init()
  end

  defp init(_), do: init()
end
