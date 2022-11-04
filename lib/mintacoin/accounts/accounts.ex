defmodule Mintacoin.Accounts do
  @moduledoc """
  This module is the responsible for the CRUD operations for accounts and also for the aggregate operations within the accounts context.
  """
  import Ecto.Query

  alias Ecto.{Changeset, UUID}

  alias Mintacoin.{
    Account,
    Accounts.Cipher,
    Accounts.Keypair,
    Asset,
    AssetHolder,
    AssetHolders,
    Blockchain,
    Repo,
    Wallet
  }

  alias Mintacoin.Accounts.Workers.CreateAccount, as: CreateAccountWorker
  alias Mintacoin.Accounts.Workers.CreateTrustline, as: CreateTrustlineWorker

  @type id :: UUID.t()
  @type address :: String.t()
  @type seed_words :: String.t()
  @type signature :: String.t() | nil
  @type account :: Account.t() | nil
  @type asset :: Asset.t()
  @type asset_holder :: AssetHolder.t()
  @type asset_code :: String.t()
  @type params :: map()
  @type wallet :: Wallet.t()
  @type encrypted_key :: String.t()
  @type accounts :: list(Account.t()) | []
  @type error ::
          Changeset.t()
          | :decoding_error
          | :invalid_address
          | :invalid_seed_words
          | :encryption_error
          | :asset_not_found
          | :blockchain_not_found

  @spec create(Mintacoin.Blockchain.t()) :: {:ok, Account.t()} | {:error, error()}
  def create(%Blockchain{id: blockchain_id}) do
    with {:ok, %Account{id: account_id, signature: signature} = account} <- create_db_record(),
         {:ok, encrypted_signature} <- Cipher.encrypt_with_system_key(signature) do
      %{
        account_id: account_id,
        blockchain_id: blockchain_id,
        encrypted_signature: encrypted_signature
      }
      |> CreateAccountWorker.new()
      |> Oban.insert()

      {:ok, account}
    end
  end

  @spec create_db_record :: {:ok, Account.t()} | {:error, error()}
  def create_db_record do
    signature_fields = Keypair.build_signature_fields()

    %Account{}
    |> Account.create_changeset(signature_fields)
    |> Repo.insert()
  end

  @spec create_trustline(params :: params()) :: {:ok, asset_holder()} | {:error, error()}
  def create_trustline(%{
        asset: %{id: asset_id, code: code},
        trustor_wallet: %Wallet{id: trustor_wallet_id} = trustor_wallet,
        signature: signature
      }) do
    case system_encrypt_secret_key(trustor_wallet, signature) do
      {:ok, encrypted_secret_key} ->
        trustor_wallet_id
        |> AssetHolders.retrieve_by_wallet_id_and_asset_id(asset_id)
        |> process_trustor(asset_id, trustor_wallet)
        |> dispatch_create_trustline_job(encrypted_secret_key, code)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec retrieve_by_id(id :: id()) :: {:ok, account()}
  def retrieve_by_id(id), do: {:ok, Repo.get(Account, id)}

  @spec retrieve_by_address(address :: address()) :: {:ok, account()}
  def retrieve_by_address(address), do: {:ok, Repo.get_by(Account, address: address)}

  @spec recover_signature(address :: address(), seed_words :: seed_words()) ::
          {:ok, signature()} | {:error, error()}
  def recover_signature(address, seed_words) do
    with {:ok, %Account{encrypted_signature: encrypted_signature}} <-
           retrieve_by_address(address),
         {:ok, entropy} <- Keypair.get_entropy_from_seed_words(seed_words) do
      Cipher.decrypt(encrypted_signature, entropy)
    else
      {:ok, nil} -> {:error, :invalid_address}
      error -> error
    end
  end

  @spec retrieve_accounts_by_asset_id(asset_id :: id()) :: {:ok, accounts()}
  def retrieve_accounts_by_asset_id(asset_id) do
    query =
      from(account in Account,
        join: asset_holder in AssetHolder,
        on: account.id == asset_holder.account_id,
        where: asset_holder.asset_id == ^asset_id
      )

    {:ok, Repo.all(query)}
  end

  @spec system_encrypt_secret_key(
          wallet :: wallet(),
          signature :: signature()
        ) :: {:ok, encrypted_key()} | {:error, error()}
  defp system_encrypt_secret_key(
         %{encrypted_secret_key: encrypted_secret_key},
         signature
       ) do
    with {:ok, secret_key} <- Cipher.decrypt(encrypted_secret_key, signature) do
      Cipher.encrypt_with_system_key(secret_key)
    end
  end

  @spec process_trustor(
          asset_holder :: {:ok, asset_holder() | nil},
          asset_id :: id(),
          trustor_wallet :: wallet()
        ) :: {:ok, asset_holder()} | {:error, error()}
  defp process_trustor({:ok, nil}, asset_id, %Wallet{
         id: wallet_id,
         account_id: account_id,
         blockchain_id: blockchain_id
       }) do
    AssetHolders.create(%{
      blockchain_id: blockchain_id,
      account_id: account_id,
      asset_id: asset_id,
      wallet_id: wallet_id,
      is_minter: false
    })
  end

  defp process_trustor({:ok, %AssetHolder{} = asset_holder}, _asset_id, _wallet),
    do: {:ok, asset_holder}

  @spec dispatch_create_trustline_job(
          asset_holder :: {:ok, asset_holder()},
          encrypted_secret_key :: encrypted_key(),
          asset_code :: asset_code()
        ) :: {:ok, asset_holder()} | {:error, error()}
  defp dispatch_create_trustline_job(
         {:ok, %AssetHolder{id: asset_holder_id} = asset_holder},
         encrypted_secret_key,
         asset_code
       ) do
    %{
      asset_holder_id: asset_holder_id,
      encrypted_secret_key: encrypted_secret_key,
      asset_code: asset_code
    }
    |> CreateTrustlineWorker.new()
    |> Oban.insert()

    {:ok, asset_holder}
  end
end
