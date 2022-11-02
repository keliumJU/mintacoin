defmodule Mintacoin.Asset do
  @moduledoc """
  Ecto schema for Asset
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Mintacoin.{AssetHolder, Balance, BlockchainTx, Payment}

  @type code :: String.t()
  @type supply :: String.t()
  @type t :: %__MODULE__{code: code(), supply: supply()}

  @code_regex ~r/^[[:alnum:]]{1,10}$/

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "assets" do
    field(:code, :string)
    field(:supply, :string)

    has_many(:blockchain_txs, BlockchainTx)
    has_many(:asset_holders, AssetHolder)
    has_many(:balances, Balance)
    has_many(:payments, Payment)

    timestamps()
  end

  @spec changeset(asset :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def changeset(asset, changes) do
    asset
    |> cast(changes, [:supply])
    |> validate_required([:supply])
  end

  @spec create_changeset(asset :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def create_changeset(asset, changes) do
    asset
    |> cast(changes, [:code, :supply])
    |> validate_required([:code, :supply])
    |> validate_format(:code, @code_regex, message: "code must be alphanumeric")
  end
end
