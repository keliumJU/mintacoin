defmodule Mintacoin.Payments.Crypto do
  @moduledoc """
  This module is responsible to handle the crypto calls for the different blockchains
  """
  @behaviour Mintacoin.Payments.Crypto.Spec

  alias Mintacoin.{Blockchain, Payments.Stellar}

  @type blockchain :: String.t()
  @type impl :: Stellar
  @type status :: :ok | :error

  @impl true
  def create_payment(opts \\ []) do
    blockchain = Keyword.get(opts, :blockchain, Blockchain.default())

    impl(blockchain).create_payment(opts)
  end

  @spec impl(blockchain :: blockchain()) :: impl()
  defp impl("stellar"), do: Application.get_env(:mintacoin, :crypto_impl, Stellar)
end
