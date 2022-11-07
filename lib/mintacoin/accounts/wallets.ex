defmodule Mintacoin.Wallets do
  @moduledoc """
  This module is responsible for doing the CRUD operations for Wallets
  """
  import Ecto.Query

  alias Ecto.{Changeset, UUID}
  alias Mintacoin.{Account, Repo, Wallet}

  @type id :: UUID.t()
  @type public_key :: String.t()
  @type changes :: map()
  @type wallet :: Wallet.t() | nil
  @type error :: Changeset.t()
  @type address :: String.t()

  @spec create(changes :: changes()) :: {:ok, Wallet.t()} | {:error, error()}
  def create(changes) do
    %Wallet{}
    |> Wallet.changeset(changes)
    |> Repo.insert()
  end

  @spec retrieve_by_id(id :: id()) :: {:ok, wallet()}
  def retrieve_by_id(id), do: {:ok, Repo.get(Wallet, id)}

  @spec retrieve_by_public_key(public_key :: public_key()) :: {:ok, wallet()}
  def retrieve_by_public_key(public_key), do: {:ok, Repo.get_by(Wallet, public_key: public_key)}

  @spec retrieve_by_account_id_and_blockchain_id(account_id :: id(), blockchain_id :: id()) ::
          {:ok, wallet()}
  def retrieve_by_account_id_and_blockchain_id(account_id, blockchain_id),
    do: {:ok, Repo.get_by(Wallet, account_id: account_id, blockchain_id: blockchain_id)}

  @spec retrieve_by_account_address_and_blockchain_id(address :: address(), blockchain_id :: id()) ::
          {:ok, wallet()}
  def retrieve_by_account_address_and_blockchain_id(address, blockchain_id) do
    query =
      from(wallet in Wallet,
        join: account in Account,
        on: wallet.account_id == account.id,
        where: account.address == ^address and wallet.blockchain_id == ^blockchain_id
      )

    {:ok, Repo.one(query)}
  end
end
