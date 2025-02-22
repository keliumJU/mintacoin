defmodule Mintacoin.Account do
  @moduledoc """
  Ecto schema for Account
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Mintacoin.Wallet

  @type t :: %__MODULE__{
          address: String.t(),
          encrypted_signature: String.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "accounts" do
    field(:address, :string)
    field(:encrypted_signature, :string)

    field(:signature, :string, virtual: true)
    field(:seed_words, :string, virtual: true)

    has_many(:wallets, Wallet)

    timestamps()
  end

  @spec create_changeset(account :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def create_changeset(account, changes) do
    account
    |> cast(changes, [
      :address,
      :encrypted_signature,
      :seed_words,
      :signature
    ])
    |> validate_required([:address, :encrypted_signature])
    |> unique_constraint([:address])
    |> unique_constraint([:encrypted_signature])
  end
end
