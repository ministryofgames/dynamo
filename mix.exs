defmodule Dynamo.Mixfile do
  use Mix.Project

  def project do
    [app: :dynamo,
     version: "0.0.2",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :iam_role, :hackney, :jsone]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:iam_role, git: "git://github.com/ministryofgames/iam_role.git", branch: "master"},
      {:jsone, "~> 1.2"},
      {:hackney, "~> 1.3"}
    ]
  end
end
