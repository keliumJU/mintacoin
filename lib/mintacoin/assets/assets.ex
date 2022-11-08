defmodule Mintacoin.Assets do
  @moduledoc """
  This module is the responsible for the CRUD operations for assets and also for the aggregate operations within the assets context.
  """
  alias Ecto.{Changeset, UUID}
  alias Mintacoin.{Accounts.Cipher, Asset, AssetHolder, AssetHolders, Repo, Wallet}
  alias Mintacoin.Assets.Workers.CreateAsset, as: CreateAssetWorker

  @type id :: UUID.t()
  @type changes :: map()
  @type error :: Changeset.t() | :decoding_error | :invalid_supply_format
  @type asset :: Asset.t()
  @type asset_code :: Asset.code()
  @type asset_supply :: Asset.supply()
  @type amount :: String.t() | integer() | float()
  @type params :: map()
  @type asset_holder :: AssetHolder.t()
  @type wallet :: Wallet.t()
  @type signature :: String.t()
  @type encrypted_key :: String.t()

  @spec create(params :: params()) :: {:ok, asset()} | {:error, error()}
  def create(%{
        wallet: %Wallet{id: wallet_id, blockchain_id: blockchain_id} = wallet,
        signature: signature,
        asset_code: asset_code,
        asset_supply: asset_supply
      }) do
    with {:ok, asset_supply} <- validate_supply(asset_supply),
         {:ok, encrypted_key} <- system_encrypt_private_key(wallet, signature) do
      wallet_id
      |> AssetHolders.retrieve_minter_by_wallet_id_and_asset_code(asset_code)
      |> process_asset_creation(asset_code, asset_supply)
      |> dispatch_crate_asset_job(wallet, encrypted_key, blockchain_id, asset_supply)
    end
  end

  @spec create_db_record(changes :: changes()) :: {:ok, asset()} | {:error, error()}
  def create_db_record(changes) do
    %Asset{}
    |> Asset.create_changeset(changes)
    |> Repo.insert()
  end

  @spec update(id :: id(), changes :: changes()) :: {:ok, asset()} | {:error, error()}
  def update(id, changes) do
    Asset
    |> Repo.get(id)
    |> Asset.changeset(changes)
    |> Repo.update()
  end

  @spec increase_supply(id :: id(), amount :: amount()) :: {:ok, asset()} | {:error, error()}
  def increase_supply(id, amount) do
    %Asset{supply: supply} = asset = Repo.get(Asset, id)

    new_supply =
      supply
      |> Decimal.add(amount)
      |> Decimal.to_string(:normal)

    asset
    |> Asset.changeset(%{supply: new_supply})
    |> Repo.update()
  end

  @spec retrieve_by_id(id :: id()) :: {:ok, asset() | nil}
  def retrieve_by_id(id), do: {:ok, Repo.get(Asset, id)}

  @spec process_asset_creation(
          asset_holder :: {:ok, asset_holder() | nil},
          asset_code :: asset_code(),
          asset_supply :: asset_supply()
        ) :: {:ok, asset()} | {:error, error()}
  defp process_asset_creation({:ok, %AssetHolder{asset: asset}}, _asset_code, _asset_supply),
    do: {:ok, asset}

  defp process_asset_creation({:ok, nil}, asset_code, asset_supply),
    do: create_db_record(%{code: asset_code, supply: asset_supply})

  @spec system_encrypt_private_key(
          wallet :: wallet(),
          signature :: signature()
        ) :: {:ok, encrypted_key()} | {:error, error()}
  defp system_encrypt_private_key(
         %{encrypted_secret_key: encrypted_secret_key},
         signature
       ) do
    with {:ok, secret_key} <- Cipher.decrypt(encrypted_secret_key, signature) do
      Cipher.encrypt_with_system_key(secret_key)
    end
  end

  @spec validate_supply(supply :: amount()) :: {:ok, asset_supply()} | {:error, error()}
  defp validate_supply(supply) do
    with {:ok, number} <- Decimal.cast(supply),
         true <- Decimal.gt?(number, "0") do
      {:ok, Decimal.to_string(number)}
    else
      _error -> {:error, :invalid_supply_format}
    end
  end

  @spec dispatch_crate_asset_job(
          asset :: {:ok, asset()} | {:error, error()},
          wallet :: wallet(),
          encrypted_key :: encrypted_key(),
          blockchain_id :: id(),
          supply :: asset_supply()
        ) :: {:ok, asset()} | {:error, error()}
  defp dispatch_crate_asset_job(
         {:ok, %{id: asset_id} = asset},
         %{id: wallet_id},
         encrypted_secret_key,
         blockchain_id,
         supply
       ) do
    %{
      blockchain_id: blockchain_id,
      asset_id: asset_id,
      wallet_id: wallet_id,
      encrypted_secret_key: encrypted_secret_key,
      supply: supply
    }
    |> CreateAssetWorker.new()
    |> Oban.insert()

    {:ok, asset}
  end

  defp dispatch_crate_asset_job(error, _wallet, _encrypted_secret_key, _blockchain_id, _supply),
    do: error
end
