defmodule Axter.Mixfile do
  use Mix.Project

  def project do
    [ app: :axter,
      version: "0.0.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [
     registered: [:data_store],
     applications: [:crypto],
     mod: {Axter.Application, []}
    ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [{:nested, github: "jeremyjh/nested"}]
  end
end
