defmodule Mintacoin.BlockchainTx do
  @moduledoc """
  Ecto schema for BlockchainTx
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Mintacoin.{Account, Asset, AssetHolder, Blockchain, Payment, Wallet}

  @type t :: %__MODULE__{
          blockchain_id: Blockchain.t(),
          account_id: Account.t(),
          wallet_id: Wallet.t(),
          asset_id: Asset.t(),
          asset_holder_id: AssetHolder.t(),
          payment_id: Payment.t(),
          successful: boolean(),
          tx_id: String.t(),
          tx_hash: String.t(),
          tx_timestamp: String.t(),
          tx_response: map()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "blockchain_txs" do
    belongs_to(:blockchain, Blockchain, type: :binary_id)
    belongs_to(:account, Account, type: :binary_id)
    belongs_to(:wallet, Wallet, type: :binary_id)
    belongs_to(:asset, Asset, type: :binary_id)
    belongs_to(:asset_holder, AssetHolder, type: :binary_id)
    belongs_to(:payment, Payment, type: :binary_id)

    field(:successful, :boolean, default: false)
    field(:tx_id, :string)
    field(:tx_hash, :string)
    field(:tx_timestamp, :string)
    field(:tx_response, :map, default: %{})

    timestamps()
  end

  @spec changeset(blockchain_tx :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def changeset(blockchain_tx, changes) do
    cast(blockchain_tx, changes, [
      :successful,
      :tx_id,
      :tx_hash,
      :tx_timestamp,
      :tx_response
    ])
  end

  @spec create_changeset(blockchain_tx :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def create_changeset(blockchain_tx, changes) do
    blockchain_tx
    |> cast(changes, [
      :blockchain_id,
      :account_id,
      :wallet_id,
      :asset_id,
      :asset_holder_id,
      :payment_id,
      :successful,
      :tx_id,
      :tx_hash,
      :tx_timestamp,
      :tx_response
    ])
    |> validate_required([:blockchain_id])
    |> foreign_key_constraint(:blockchain_id)
    |> foreign_key_constraint(:wallet_id)
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:asset_id)
    |> foreign_key_constraint(:asset_holder_id)
    |> foreign_key_constraint(:payment_id)
  end
end
