defmodule MintacoinWeb.AssetsController do
  @moduledoc """
  This module contains the asset endpoints
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

  @type accounts :: list(Account.t()) | []
  @type asset_holder :: AssetHolder.t()
  @type asset :: Asset.t()
  @type blockchain :: Blockchain.t()
  @type conn :: Plug.Conn.t()
  @type id :: UUID.t()
  @type params :: map()
  @type resource :: Asset.t() | AssetHolder.t() | String.t() | accounts() | nil
  @type response_status :: :ok | :created
  @type status :: :ok | :error
  @type template :: String.t()
  @type uuid_cast :: {:ok, id()} | :error
  @type wallet :: Wallet.t()
  @type address :: String.t()
  @type blockchain_name :: String.t()
  @type network :: :testnet | :mainnet
  @type error ::
          :blockchain_not_found
          | :invalid_supply_format
          | :decoding_error
          | :bad_request
          | :asset_not_found
          | :wallet_not_found
          | Changeset.t()

  action_fallback MintacoinWeb.FallbackController

  @default_blockchain_name Blockchain.default()

  @spec create(conn :: conn(), params :: params()) :: conn() | {:error, error()}
  def create(
        %{assigns: %{network: network}} = conn,
        %{
          "address" => address,
          "signature" => _signature,
          "asset_code" => _asset_code,
          "supply" => _supply
        } = params
      ) do
    blockchain_name = Map.get(params, "blockchain", @default_blockchain_name)

    with {:ok, blockchain} <- retrieve_blockchain(blockchain_name, network),
         {:ok, wallet} <- retrieve_wallet({:ok, blockchain}, address),
         {:ok, resource} <- create_asset({:ok, wallet}, params) do
      handle_response({:ok, resource}, conn, :created, "asset.json")
    end
  end

  def create(_conn, _params), do: {:error, :bad_request}

  @spec show(conn :: conn(), params :: params()) :: conn() | {:error, error()}
  def show(conn, %{"id" => id}) do
    uuid = UUID.cast(id)

    with {:ok, asset} <- retrieve_asset(uuid) do
      handle_response({:ok, asset}, conn, :ok, "show_asset.json")
    end
  end

  @spec show_issuer(conn :: conn(), params :: params()) :: conn() | {:error, error()}
  def show_issuer(conn, %{"id" => id}) do
    uuid = UUID.cast(id)

    with {:ok, asset_holder} <- retrieve_issuer(uuid) do
      handle_response({:ok, asset_holder}, conn, :ok, "asset_issuer.json")
    end
  end

  @spec show_accounts(conn :: conn(), params :: params()) :: conn() | {:error, error()}
  def show_accounts(conn, %{"id" => id}) do
    uuid = UUID.cast(id)

    with {:ok, accounts} <- retrieve_accounts(uuid) do
      handle_response({:ok, accounts}, conn, :ok, "asset_accounts.json")
    end
  end

  @spec retrieve_blockchain(blockchain_name :: blockchain_name(), network :: network()) ::
          {:ok, blockchain()} | {:error, error()}
  defp retrieve_blockchain(blockchain, network) do
    case Blockchains.retrieve(blockchain, network) do
      {:ok, %Blockchain{} = blockchain} -> {:ok, blockchain}
      _any -> {:error, :blockchain_not_found}
    end
  end

  @spec retrieve_wallet(
          blockchain :: {:ok, blockchain()} | {:error, error()},
          address :: address()
        ) :: {:ok, wallet()} | {:error, error()}
  defp retrieve_wallet({:ok, %Blockchain{id: blockchain_id}}, address) do
    case Wallets.retrieve_by_account_address_and_blockchain_id(address, blockchain_id) do
      {:ok, %Wallet{} = wallet} -> {:ok, wallet}
      _any -> {:error, :wallet_not_found}
    end
  end

  @spec retrieve_accounts(uuid_cast :: uuid_cast()) :: {:ok, accounts()} | {:error, error()}
  defp retrieve_accounts({:ok, id}) do
    case Accounts.retrieve_accounts_by_asset_id(id) do
      {:ok, []} -> {:error, :asset_not_found}
      accounts -> accounts
    end
  end

  defp retrieve_accounts(:error), do: {:error, :asset_not_found}

  @spec retrieve_issuer(uuid_cast :: uuid_cast()) :: {:ok, asset_holder()} | {:error, error()}
  defp retrieve_issuer({:ok, id}) do
    case AssetHolders.retrieve_minter_by_asset_id(id) do
      {:ok, nil} -> {:error, :asset_not_found}
      asset_holder -> asset_holder
    end
  end

  defp retrieve_issuer(:error), do: {:error, :asset_not_found}

  @spec retrieve_asset(uuid_cast :: uuid_cast()) :: {:ok, asset()} | {:error, error()}
  defp retrieve_asset({:ok, id}) do
    case Assets.retrieve_by_id(id) do
      {:ok, nil} -> {:error, :asset_not_found}
      asset -> asset
    end
  end

  defp retrieve_asset(:error), do: {:error, :asset_not_found}

  @spec create_asset(wallet :: {:ok, wallet()} | {:error, error()}, params :: params()) ::
          {:ok, asset()} | {:error, error()}
  defp create_asset({:ok, wallet}, %{
         "signature" => signature,
         "asset_code" => asset_code,
         "supply" => supply
       }) do
    Assets.create(%{
      wallet: wallet,
      signature: signature,
      asset_code: asset_code,
      asset_supply: supply
    })
  end

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
