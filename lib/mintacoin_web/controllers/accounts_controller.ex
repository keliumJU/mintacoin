defmodule MintacoinWeb.AccountsController do
  @moduledoc """
  This module contains the account endpoints
  """

  use MintacoinWeb, :controller

  alias Ecto.{Changeset, UUID}

  alias Mintacoin.{
    Account,
    Accounts,
    Asset,
    AssetHolder,
    AssetHolders,
    Assets,
    Blockchain,
    Blockchains,
    Wallet,
    Wallets
  }

  @type address :: String.t()
  @type account :: Account.t()
  @type asset :: Asset.t()
  @type asset_holder :: AssetHolder.t()
  @type blockchain :: Blockchain.t() | nil
  @type conn :: Plug.Conn.t()
  @type id :: UUID.t()
  @type params :: map()
  @type response_status :: :ok | :created
  @type status :: :ok | :error
  @type template :: String.t()
  @type uuid_cast :: {:ok, id()} | :error
  @type resource :: Account.t() | Asset.t() | String.t() | list() | nil
  @type signature :: String.t()
  @type wallet :: Wallet.t()
  @type error ::
          :blockchain_not_found
          | :bad_request
          | :decoding_error
          | :invalid_address
          | :invalid_seed_words
          | :encryption_error
          | :asset_not_found
          | :wallet_not_found
          | Changeset.t()

  action_fallback MintacoinWeb.FallbackController

  @spec create(conn :: conn(), params :: params()) :: conn() | {:error, error()}
  def create(conn, %{"blockchain" => blockchain}) do
    %{assigns: %{network: network}} = conn
    with {:ok, blockchain_struct} <- Blockchains.retrieve(blockchain, network) ,
         {:ok, resource} <- create_account({:ok, blockchain_struct}) do
          handle_response({:ok, resource}, conn, :created, "account.json")
    end
  end

  def create(_conn, _params), do: {:error, :bad_request}

  @spec create_account({:ok, blockchain()}) :: {status(), resource()}
  defp create_account({:ok, %Blockchain{} = blockchain}), do: Accounts.create(blockchain)
  defp create_account({:ok, nil}), do: {:error, :blockchain_not_found}

  @spec recover(conn :: conn(), params :: params()) :: {:ok, resource()} | {:error, error()}
  def recover(conn, %{"address" => address, "seed_words" => seed_words}) do
    with {:ok, resource} <- Accounts.recover_signature(address, seed_words) do
      handle_response({:ok, resource}, conn, :ok, "signature.json")
    end
  end

  def recover(_conn, _params), do: {:error, :bad_request}

  @spec create_trustline(conn :: conn(), params :: params()) :: conn() | {:error, error()}
  def create_trustline(
        conn,
        %{"address" => address, "asset_id" => asset_id, "signature" => signature}
      ) do
    asset = UUID.cast(asset_id)
    IO.puts("this is asset")
    IO.inspect(asset)

    with {:ok, %{asset: asset, blockchain_id: blockchain_id}} <- retrieve_asset_and_blockchain(asset),
      {:ok, wallet} <- retrieve_wallet({:ok, %{blockchain_id: blockchain_id}}, address),
      {:ok, resource} <-  process_trustline({:ok, wallet}, {:ok, %{asset: asset}}, signature) do
        handle_response({:ok, resource}, conn, :created, "trustline.json")
    end
  end

  def create_trustline(_conn, _params), do: {:error, :bad_request}

  @spec show_assets(conn :: conn(), params :: params()) :: conn() | {:error, error()}
  def show_assets(conn, %{"address" => address}) do
    account = Accounts.retrieve_by_address(address)
    with {:ok, resource} <- retrieve_assets(account) do
      handle_response({:ok, resource}, conn, :ok, "assets.json")
    end
  end

  @spec retrieve_assets(account :: {:ok, account() | nil}) :: {:ok, list()} | {:error, error()}
  defp retrieve_assets({:ok, %Account{id: account_id}}),
    do: AssetHolders.retrieve_by_account_id(account_id)

  defp retrieve_assets({:ok, nil}), do: {:error, :invalid_address}

  @spec retrieve_asset_and_blockchain(uuid_cast :: uuid_cast()) ::
          {:ok, map()} | {:error, error()}
  defp retrieve_asset_and_blockchain({:ok, id}) do
    case AssetHolders.retrieve_minter_by_asset_id(id) do
      {:ok, %AssetHolder{asset: asset, blockchain_id: blockchain_id}} ->
        {:ok, %{asset: asset, blockchain_id: blockchain_id}}
      {:ok, nil} ->
        {:error, :asset_not_found}
    end
  end

  defp retrieve_asset_and_blockchain(:error), do: {:error, :asset_not_found}

  @spec retrieve_wallet(blockchain_id :: {:ok, map()} | {:error, error()}, address :: address()) ::
          {:ok, wallet()} | {:error, error()}
  defp retrieve_wallet({:ok, %{blockchain_id: blockchain_id}}, address) do
    case Wallets.retrieve_by_account_address_and_blockchain_id(address, blockchain_id) do
      {:ok, %Wallet{} = wallet} -> {:ok, wallet}
      {:ok, nil} -> {:error, :wallet_not_found}
    end
  end

  #defp retrieve_wallet(error, _address), do: error

  @spec process_trustline(
          wallet :: {:ok, wallet()} | {:error, error()},
          asset :: {:ok, map()},
          signature :: signature()
        ) :: {:ok, asset()} | {:error, error()}
  defp process_trustline({:ok, %Wallet{} = wallet}, {:ok, %{asset: asset}}, signature) do
    case Accounts.create_trustline(%{asset: asset, trustor_wallet: wallet, signature: signature}) do
      {:ok, %AssetHolder{asset_id: asset_id}} -> Assets.retrieve_by_id(asset_id)
      {:error, error} -> {:error, error}
    end
  end

  #defp process_trustline(error, _asset, _params), do: error

  @spec handle_response(
          {:ok, resource :: resource()} | {:error, error()},
          conn :: conn(),
          status :: response_status(),
          template :: template()
        ) :: conn()
  defp handle_response({:ok, resource}, conn, status, template) do
    conn
    |> put_status(status)
    |> render(template, resource: resource)
  end

end
