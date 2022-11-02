defmodule Mintacoin.BlockchainTxFactory do
  @moduledoc """
  Allow the creation of blockchains transaction while testing.
  """

  alias Ecto.UUID
  alias Mintacoin.BlockchainTx

  defmacro __using__(_opts) do
    quote do
      @spec blockchain_tx_factory(attrs :: map()) :: BlockchainTx.t()
      def blockchain_tx_factory(attrs) do
        account = Map.get(attrs, :account, insert(:account))
        blockchain = Map.get(attrs, :blockchain, insert(:blockchain))
        wallet = Map.get(attrs, :wallet, insert(:wallet, blockchain: blockchain))
        asset = Map.get(attrs, :asset, insert(:asset))
        asset_holder = Map.get(attrs, :asset_holder, insert(:asset_holder))
        payment = Map.get(attrs, :payment, insert(:payment))
        successful = Map.get(attrs, :successful, false)
        tx_timestamp = Map.get(attrs, :tx_timestamp, sequence(:tx_timestamp, &"123456789#{&1}"))
        tx_response = Map.get(attrs, :tx_response, %{})

        tx_id =
          Map.get(
            attrs,
            :tx_id,
            sequence(
              :tx_id,
              &"7f82fe6ac195e7674f7bdf7a3416683ffd55c8414978c70bf4da08ac64fea129#{&1}"
            )
          )

        tx_hash =
          Map.get(
            attrs,
            :tx_hash,
            sequence(
              :tx_hash,
              &"7f82fe6ac195e7674f7bdf7a3416683ffd55c8414978c70bf4da08ac64fea129#{&1}"
            )
          )

        %BlockchainTx{
          id: UUID.generate(),
          account: account,
          blockchain: blockchain,
          wallet: wallet,
          asset: asset,
          asset_holder: asset_holder,
          payment: payment,
          successful: successful,
          tx_id: tx_id,
          tx_hash: tx_hash,
          tx_timestamp: tx_timestamp,
          tx_response: tx_response
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
