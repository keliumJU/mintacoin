# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Mintacoin.Repo.insert!(%Mintacoin.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
  alias Mintacoin.{Repo, Blockchain}

  network = Application.get_env(:mintacoin, :blockchains_network, :testnet)

  run_seeds = fn 
    false -> Repo.insert!(%Blockchain{name: Blockchain.default(), network: network})
    true -> :ok 
  end

  Blockchain
    |> Repo.exists?()
    |> run_seeds.()
