defmodule Mintacoin.Payment do
  @moduledoc """
  Ecto schema for Payments
  """

  use Ecto.Schema

  import Ecto.Changeset
  import EctoEnum

  alias Ecto.{Changeset, UUID}
  alias Mintacoin.{Account, Asset, Blockchain, BlockchainTx}

  @type amount :: String.t()
  @type id :: UUID.t()
  @type status :: atom()
  @type successful :: boolean()
  @type t :: %__MODULE__{
          blockchain_id: id(),
          source_account_id: id(),
          destination_account_id: id(),
          asset_id: id(),
          amount: amount(),
          status: status(),
          successful: successful()
        }

  defenum(Status, :status, [:completed, :processing, :failed])

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "payments" do
    field(:amount, :string)
    field(:status, Status, default: :processing)
    field(:successful, :boolean)

    belongs_to(:blockchain, Blockchain, type: :binary_id)
    belongs_to(:source_account, Account, type: :binary_id)
    belongs_to(:destination_account, Account, type: :binary_id)
    belongs_to(:asset, Asset, type: :binary_id)

    has_many(:blockchain_txs, BlockchainTx)

    timestamps()
  end

  @spec changeset(payment :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def changeset(payment, changes), do: cast(payment, changes, [:status, :successful])

  @spec create_changeset(payment :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def create_changeset(payment, changes) do
    payment
    |> cast(changes, [
      :blockchain_id,
      :source_account_id,
      :destination_account_id,
      :asset_id,
      :amount,
      :status,
      :successful
    ])
    |> validate_required([
      :blockchain_id,
      :source_account_id,
      :destination_account_id,
      :asset_id,
      :amount,
      :status,
      :successful
    ])
    |> foreign_key_constraint(:blockchain_id)
    |> foreign_key_constraint(:source_account_id)
    |> foreign_key_constraint(:destination_account_id)
    |> foreign_key_constraint(:asset_id)
  end
end
