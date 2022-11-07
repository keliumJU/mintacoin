defmodule MintacoinWeb.AccountsControllerTest do
  @moduledoc """
  This module is used to test account's endpoints
  """

  use MintacoinWeb.ConnCase
  use Oban.Testing, repo: Mintacoin.Repo

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Mintacoin.{Accounts, Accounts.Cipher, Assets, Balances}
  alias Mintacoin.Accounts.StellarMock, as: AccountStellarMock
  alias Mintacoin.Assets.StellarMock, as: AssetStellarMock

  setup %{conn: conn} do
    Application.put_env(:mintacoin, :crypto_impl, AccountStellarMock)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :crypto_impl)
    end)

    address = "GB3ZYW3WZWQU6CAEA6EQ4ALER456DPVBC6YLQRDKTTSNEVJOGFCECX5L"
    signature = "SB3RAKL2MRYZ53WJQAL5RJ42LPCMJTNDH4W7UWVRJA3GTEC66BC7VNUT"

    blockchain = insert(:blockchain, %{name: "stellar", network: "testnet"})
    account = insert(:account, %{address: address, signature: signature})

    api_token = Application.get_env(:mintacoin, :api_token)

    conn_authenticated =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{api_token}")

    conn_invalid_token =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer INVALID_TOKEN")

    %{
      account: account,
      address: address,
      signature: signature,
      blockchain: blockchain,
      conn_authenticated: conn_authenticated,
      conn_unauthenticated: put_req_header(conn, "accept", "application/json"),
      conn_invalid_token: conn_invalid_token,
      not_existing_uuid: "49354685-d6c7-4c4e-81fe-6144ab3122fa"
    }
  end

  describe "create/2" do
    test "with valid params", %{conn_authenticated: conn, blockchain: %{name: blockchain_name}} do
      conn = post(conn, Routes.accounts_path(conn, :create), %{blockchain: blockchain_name})

      %{
        "data" => %{
          "address" => _address,
          "signature" => _signature,
          "seed_words" => _seed_words
        },
        "status" => 201
      } = json_response(conn, 201)
    end

    test "when blockchain is not valid", %{conn_authenticated: conn} do
      conn = post(conn, Routes.accounts_path(conn, :create), %{blockchain: "INVALID"})

      %{
        "code" => "blockchain_not_found",
        "detail" => "The introduced blockchain doesn't exist",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when blockchain is not present", %{conn_authenticated: conn} do
      conn = post(conn, Routes.accounts_path(conn, :create))

      json_response(conn, 400)
    end

    test "when authenticate token is invalid", %{
      conn_invalid_token: conn,
      blockchain: %{name: blockchain_name}
    } do
      conn = post(conn, Routes.accounts_path(conn, :create), %{blockchain: blockchain_name})

      %{
        "code" => 401,
        "detail" => "Invalid authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end

    test "when authenticate token is not submit", %{
      conn_unauthenticated: conn,
      blockchain: %{name: blockchain_name}
    } do
      conn = post(conn, Routes.accounts_path(conn, :create), %{blockchain: blockchain_name})

      %{
        "code" => 401,
        "detail" => "Missing authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end
  end

  describe "recover/2" do
    test "when params are valid", %{
      conn_authenticated: conn,
      address: address,
      account: %{signature: signature, seed_words: seed_words}
    } do
      conn = post(conn, Routes.accounts_path(conn, :recover, address), %{seed_words: seed_words})

      %{"data" => %{"signature" => ^signature}, "status" => 200} = json_response(conn, 200)
    end

    test "when address is invalid", %{
      conn_authenticated: conn,
      account: %{seed_words: seed_words}
    } do
      conn =
        post(conn, Routes.accounts_path(conn, :recover, "INVALID_ADDRESS"), %{
          seed_words: seed_words
        })

      %{"code" => "invalid_address", "detail" => "The address is invalid", "status" => 400} =
        json_response(conn, 400)
    end

    test "when seed_words is invalid", %{conn_authenticated: conn, address: address} do
      conn =
        post(conn, Routes.accounts_path(conn, :recover, address), %{
          seed_words: "INVALID_SEED_WORDS"
        })

      %{
        "code" => "invalid_seed_words",
        "detail" => "The seed words are invalid",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when seed_words are not present", %{conn_authenticated: conn, address: address} do
      conn = post(conn, Routes.accounts_path(conn, :recover, address))

      json_response(conn, 400)
    end

    test "when authorization Bearer token is invalid", %{
      conn_invalid_token: conn,
      address: address,
      account: %{seed_words: seed_words}
    } do
      conn = post(conn, Routes.accounts_path(conn, :recover, address), %{seed_words: seed_words})

      %{
        "code" => 401,
        "detail" => "Invalid authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end

    test "when authorization Bearer token is not submit", %{
      conn_unauthenticated: conn,
      address: address,
      account: %{seed_words: seed_words}
    } do
      conn = post(conn, Routes.accounts_path(conn, :recover, address), %{seed_words: seed_words})

      %{
        "code" => 401,
        "detail" => "Missing authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end
  end

  describe "create_trustline/1" do
    setup [:successful_transaction, :create_asset, :create_trustor]

    test "with valid params", %{
      conn_authenticated: conn,
      asset: %{id: asset_id, code: asset_code, supply: asset_supply},
      trustor_account: %{address: address, signature: signature}
    } do
      conn =
        post(conn, Routes.accounts_path(conn, :create_trustline, address, asset_id), %{
          signature: signature
        })

      %{
        "data" => %{
          "id" => ^asset_id,
          "code" => ^asset_code,
          "supply" => ^asset_supply
        },
        "status" => 201
      } = json_response(conn, 201)
    end

    test "with invalid params", %{
      conn_authenticated: conn,
      asset: %{id: asset_id},
      trustor_account: %{address: address}
    } do
      conn = post(conn, Routes.accounts_path(conn, :create_trustline, address, asset_id), %{})

      %{"errors" => %{"detail" => "Bad Request"}} = json_response(conn, 400)
    end

    test "when address doesn't exist", %{
      conn_authenticated: conn,
      asset: %{id: asset_id},
      trustor_account: %{signature: signature}
    } do
      conn =
        post(conn, Routes.accounts_path(conn, :create_trustline, "undefined", asset_id), %{
          signature: signature
        })

      %{
        "code" => "wallet_not_found",
        "detail" =>
          "The introduced address doesn't exist or doesn't have associated the blockchain",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when asset id doesn't exist", %{
      conn_authenticated: conn,
      not_existing_uuid: not_existing_uuid,
      trustor_account: %{address: address, signature: signature}
    } do
      conn =
        post(conn, Routes.accounts_path(conn, :create_trustline, address, not_existing_uuid), %{
          signature: signature
        })

      %{
        "code" => "asset_not_found",
        "detail" => "The introduced asset doesn't exist",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "with invalid asset id", %{
      conn_authenticated: conn,
      trustor_account: %{address: address, signature: signature}
    } do
      conn =
        post(conn, Routes.accounts_path(conn, :create_trustline, address, "invalid"), %{
          signature: signature
        })

      %{
        "code" => "asset_not_found",
        "detail" => "The introduced asset doesn't exist",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when the signature is invalid", %{
      conn_authenticated: conn,
      asset: %{id: asset_id},
      trustor_account: %{address: address}
    } do
      conn =
        post(conn, Routes.accounts_path(conn, :create_trustline, address, asset_id), %{
          signature: "invalid"
        })

      %{
        "code" => "decoding_error",
        "detail" => "The signature is invalid",
        "status" => 400
      } = json_response(conn, 400)
    end
  end

  describe "show_assets/2 when the user has assets" do
    setup [:successful_transaction, :create_asset, :create_trustor, :create_trustline]

    test "with valid params", %{
      conn_authenticated: conn,
      trustor_account: %{address: address},
      asset: %{id: asset_id, code: asset_code},
      blockchain: %{name: blockchain_name},
      trustor_balance: %{balance: balance},
      trustor_asset_holder: %{is_minter: is_minter}
    } do
      conn = get(conn, Routes.accounts_path(conn, :show_assets, address))

      %{
        "data" => [
          %{
            "asset" => ^asset_code,
            "asset_id" => ^asset_id,
            "balance" => ^balance,
            "blockchain" => ^blockchain_name,
            "minter" => ^is_minter
          }
        ],
        "status" => 200
      } = json_response(conn, 200)
    end

    test "when address doesn't exists", %{
      conn_authenticated: conn,
      not_existing_uuid: not_existing_uuid
    } do
      conn = get(conn, Routes.accounts_path(conn, :show_assets, not_existing_uuid))

      %{
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when authenticate token is invalid", %{
      conn_invalid_token: conn,
      trustor_account: %{address: address}
    } do
      conn = get(conn, Routes.accounts_path(conn, :show_assets, address))

      %{
        "code" => 401,
        "detail" => "Invalid authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end

    test "when authenticate token is not submit", %{
      conn_unauthenticated: conn,
      trustor_account: %{address: address}
    } do
      conn = get(conn, Routes.accounts_path(conn, :show_assets, address))

      %{
        "code" => 401,
        "detail" => "Missing authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end
  end

  describe "show_assets/2 when the user doesn't have assets" do
    setup [:successful_transaction, :create_asset, :create_trustor]

    test "with valid params", %{conn_authenticated: conn, trustor_account: %{address: address}} do
      conn = get(conn, Routes.accounts_path(conn, :show_assets, address))

      %{
        "data" => [],
        "status" => 200
      } = json_response(conn, 200)
    end
  end

  defp create_asset(%{blockchain: blockchain}) do
    asset_code = "MTK"
    supply = "55.65"

    %{signature: signature} = account = insert(:account)

    secret_key = "SBJCNL6H5WFDK2CUAWU2IAWGWQLGER77URPYXUJ5B4N4GY2HNEBL5JJG"
    {:ok, encrypted_secret_key} = Cipher.encrypt(secret_key, signature)

    wallet =
      insert(:wallet, %{
        account: account,
        blockchain: blockchain,
        encrypted_secret_key: encrypted_secret_key
      })

    {:ok, asset} =
      Assets.create(%{
        wallet: wallet,
        signature: signature,
        asset_code: asset_code,
        asset_supply: supply
      })

    %{
      asset: asset,
      blockchain: blockchain
    }
  end

  defp create_trustor(%{blockchain: blockchain}) do
    %{signature: signature} = account = insert(:account)

    secret_key = "SDCRAVD2NLVJSLMUU2EZRMT57JUNQG7NAG3FOUVRPBPT6DCGHTQW7I3W"
    {:ok, encrypted_secret_key} = Cipher.encrypt(secret_key, signature)

    wallet =
      insert(:wallet, %{
        account: account,
        blockchain: blockchain,
        encrypted_secret_key: encrypted_secret_key
      })

    %{
      trustor_account: account,
      trustor_wallet: wallet
    }
  end

  defp create_trustline(%{
         trustor_wallet: %{id: wallet_id} = trustor_wallet,
         asset: %{id: asset_id} = asset,
         trustor_account: %{signature: signature}
       }) do
    {:ok, asset_holder} =
      Accounts.create_trustline(%{
        asset: asset,
        trustor_wallet: trustor_wallet,
        signature: signature
      })

    {:ok, balance} = Balances.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)

    %{trustor_asset_holder: asset_holder, trustor_balance: balance}
  end

  defp successful_transaction(_context) do
    Application.put_env(:mintacoin, :crypto_impl, AssetStellarMock)
    Application.put_env(:stellar_mock, :tx_status, true)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :crypto_impl)
      Application.delete_env(:stellar_mock, :tx_status)
    end)
  end
end
