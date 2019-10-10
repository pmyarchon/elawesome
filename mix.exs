defmodule Elawesome.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elawesome,
      version: "0.1.0",
      elixir: "~> 1.9",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  def application do
    [
      applications: [:logger, :cowboy, :plug, :phoenix, :earmark],
      mod: {Elawesome, []}
    ]
  end

  # Dependencies
  defp deps do
    [
      {:cowboy, "~> 1.1.2"},
      {:phoenix, "~> 1.4"},
      {:plug_cowboy, "~> 1.0"},
      {:jason, "~> 1.1"},
      {:earmark, "~> 1.4"}
    ]
  end
end
