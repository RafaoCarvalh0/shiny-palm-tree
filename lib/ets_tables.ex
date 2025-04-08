defmodule EtsTables do
  def start() do
    tables = [ets_user_gamification_data(), ets_user_gamification_events()]

    Enum.each(
      tables,
      &if :ets.whereis(&1) == :undefined do
        :ets.new(&1, [:set, :named_table, :public])
      else
        &1
      end
    )
  end

  def ets_user_gamification_data(), do: :user_gamification_data
  def ets_user_gamification_events(), do: :user_gamification_events
end
