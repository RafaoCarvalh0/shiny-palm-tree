defmodule GamificationEvent.MixProject do
  use Mix.Project

  def project do
    [
      app: :gamification_event,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp deps do
    []
  end
end
