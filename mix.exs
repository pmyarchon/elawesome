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
      applications: start_apps(),
      mod: {Elawesome, []}
    ]
  end

  # Start applications
  defp start_apps do
    [
      :logger,
      :ssl,
      :inets,
      :cowboy,
      :plug,
      :phoenix,
      :floki
    ]
  end

  # Dependencies
  defp deps do
    [
      {:cowboy, "~> 1.1.2"},
      {:phoenix, "~> 1.4"},
      {:plug_cowboy, "~> 1.0"},
      {:jason, "~> 1.1"},
      {:floki, "~> 0.23.0"}
    ]
  end
end
