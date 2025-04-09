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
    |> case do
      {:ok, user_data} ->
        Process.sleep(1500)

        IO.puts("""

        ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        Updated user data:
        #{user_data}
        ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        """)

        Process.sleep(1500)

      {:error, error} ->
        Process.sleep(1500)

        IO.puts("""

        ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        Error:
        #{error}
        ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        """)

        Process.sleep(1500)
    end
    |> init()
  end

  defp init(_), do: init()
end
