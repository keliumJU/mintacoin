defmodule Mintacoin.Blockchain do
  @moduledoc """
  Ecto schema for Blockchain
  """

  use Ecto.Schema

  import Ecto.Changeset
  import EctoEnum

  alias Ecto.Changeset
  alias Mintacoin.{AssetHolder, BlockchainTx, Payment, Wallet}

  @type name :: String.t()
  @type network :: Network
  @type t :: %__MODULE__{name: name(), network: network()}

  defenum(Network, :network, [
    :mainnet,
    :testnet
  ])

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "blockchains" do
    field(:name, :string)
    field(:network, Network)

    has_many(:wallets, Wallet)
    has_many(:blockchain_txs, BlockchainTx)
    has_many(:asset_holders, AssetHolder)
    has_many(:payments, Payment)

    timestamps()
  end

  @spec changeset(blockchain :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def changeset(blockchain, changes) do
    blockchain
    |> cast(changes, [:name, :network])
    |> validate_required([:name, :network])
    |> unique_constraint([:name, :network])
  end

  @spec default :: String.t()
  def default, do: "stellar"
end
