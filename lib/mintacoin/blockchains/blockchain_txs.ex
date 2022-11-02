defmodule Mintacoin.BlockchainTxs do
  @moduledoc """
  This module is the responsible for the CRUD operations for blockchains transactions and also for the aggregate operations within the blockchain context.
  """
  import Ecto.Query

  alias Ecto.{Changeset, UUID}
  alias Mintacoin.{BlockchainTx, Repo}

  @type id :: UUID.t()
  @type tx_id :: String.t()
  @type changes :: map()
  @type blockchain_tx :: BlockchainTx.t() | nil
  @type error :: Changeset.t()

  @spec create(changes :: changes()) :: {:ok, blockchain_tx()} | {:error, error()}
  def create(changes) do
    %BlockchainTx{}
    |> BlockchainTx.create_changeset(changes)
    |> Repo.insert()
  end

  @spec update(id :: id(), changes :: changes()) :: {:ok, blockchain_tx()} | {:error, error()}
  def update(id, changes) do
    BlockchainTx
    |> Repo.get(id)
    |> BlockchainTx.changeset(changes)
    |> Repo.update()
  end

  @spec retrieve_by_id(id :: id()) :: {:ok, blockchain_tx()}
  def retrieve_by_id(id), do: {:ok, Repo.get(BlockchainTx, id)}

  @spec retrieve_by_tx_id(tx_id :: tx_id()) :: {:ok, blockchain_tx()}
  def retrieve_by_tx_id(tx_id), do: {:ok, Repo.get_by(BlockchainTx, tx_id: tx_id)}

  @spec retrieve_by_account_id(account_id :: id()) :: {:ok, list(blockchain_tx())}
  def retrieve_by_account_id(account_id) do
    query = from(btx in BlockchainTx, where: btx.account_id == ^account_id)
    {:ok, Repo.all(query)}
  end

  @spec retrieve_by_wallet_id(wallet_id :: id()) :: {:ok, list(blockchain_tx())}
  def retrieve_by_wallet_id(wallet_id) do
    query = from(btx in BlockchainTx, where: btx.wallet_id == ^wallet_id)
    {:ok, Repo.all(query)}
  end

  @spec retrieve_by_asset_id(asset_id :: id()) :: {:ok, list(blockchain_tx())}
  def retrieve_by_asset_id(asset_id) do
    query = from(btx in BlockchainTx, where: btx.asset_id == ^asset_id)
    {:ok, Repo.all(query)}
  end

  @spec retrieve_by_asset_holder_id(asset_holder_id :: id()) :: {:ok, list(blockchain_tx())}
  def retrieve_by_asset_holder_id(asset_holder_id) do
    query = from(btx in BlockchainTx, where: btx.asset_holder_id == ^asset_holder_id)
    {:ok, Repo.all(query)}
  end

  @spec retrieve_by_payment_id(payment_id :: id()) :: {:ok, list(blockchain_tx())}
  def retrieve_by_payment_id(payment_id) do
    query = from(btx in BlockchainTx, where: btx.payment_id == ^payment_id)
    {:ok, Repo.all(query)}
  end
end
