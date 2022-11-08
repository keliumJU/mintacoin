defmodule MintacoinWeb.AssetsControllerTest do
  @moduledoc """
  This module is used to test assets's endpoints
  """

  use MintacoinWeb.ConnCase
  use Oban.Testing, repo: Mintacoin.Repo

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Mintacoin.{Accounts.Cipher, Assets.StellarMock}

  setup %{conn: conn} do
    Application.put_env(:mintacoin, :crypto_impl, StellarMock)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :crypto_impl)
    end)

    blockchain = insert(:blockchain, %{name: "stellar", network: "testnet"})

    %{signature: signature} = account = insert(:account)

    secret_key = "SBJCNL6H5WFDK2CUAWU2IAWGWQLGER77URPYXUJ5B4N4GY2HNEBL5JJG"
    {:ok, encrypted_secret_key} = Cipher.encrypt(secret_key, signature)

    wallet =
      insert(:wallet, %{
        account: account,
        blockchain: blockchain,
        encrypted_secret_key: encrypted_secret_key
      })

    api_token = Application.get_env(:mintacoin, :api_token)

    authenticated_conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{api_token}")

    invalid_authenticated_conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer INVALID_TOKEN")

    unauthenticated_conn = put_req_header(conn, "accept", "application/json")

    %{
      account: account,
      not_existing_account: "49354685-d6c7-4c4e-81fe-6144ab3122fa",
      blockchain: blockchain,
      signature: signature,
      invalid_signature: "OR4N6LBCSWMBNPJEW6KBZ62LQNKW4H7WPE5MNIOIX732LQXBU67",
      wallet: wallet,
      asset_code: "MTK",
      asset_supply: "556.3342423",
      float_supply: 231.455_344,
      integer_supply: 231,
      authenticated_conn: authenticated_conn,
      invalid_authenticated_conn: invalid_authenticated_conn,
      unauthenticated_conn: unauthenticated_conn
    }
  end

  describe "create/2" do
    test "with all valid params", %{
      authenticated_conn: conn,
      account: %{address: address, signature: signature},
      blockchain: %{name: blockchain_name},
      asset_code: asset_code,
      asset_supply: asset_supply
    } do
      conn =
        post(conn, Routes.assets_path(conn, :create), %{
          blockchain: blockchain_name,
          address: address,
          signature: signature,
          asset_code: asset_code,
          supply: asset_supply
        })

      %{
        "data" => %{
          "id" => _id,
          "code" => ^asset_code,
          "supply" => ^asset_supply
        },
        "status" => 201
      } = json_response(conn, 201)
    end

    test "with required params", %{
      authenticated_conn: conn,
      account: %{address: address, signature: signature},
      asset_code: asset_code,
      asset_supply: asset_supply
    } do
      conn =
        post(conn, Routes.assets_path(conn, :create), %{
          address: address,
          signature: signature,
          asset_code: asset_code,
          supply: asset_supply
        })

      %{
        "data" => %{
          "id" => _id,
          "code" => ^asset_code,
          "supply" => ^asset_supply
        },
        "status" => 201
      } = json_response(conn, 201)
    end

    test "with float supply", %{
      authenticated_conn: conn,
      account: %{address: address, signature: signature},
      blockchain: %{name: blockchain_name},
      asset_code: asset_code,
      float_supply: asset_supply
    } do
      conn =
        post(conn, Routes.assets_path(conn, :create), %{
          blockchain: blockchain_name,
          address: address,
          signature: signature,
          asset_code: asset_code,
          supply: asset_supply
        })

      string_supply = Float.to_string(asset_supply)

      %{
        "data" => %{
          "id" => _id,
          "code" => ^asset_code,
          "supply" => ^string_supply
        },
        "status" => 201
      } = json_response(conn, 201)
    end

    test "with integer supply", %{
      authenticated_conn: conn,
      account: %{address: address, signature: signature},
      blockchain: %{name: blockchain_name},
      asset_code: asset_code,
      integer_supply: asset_supply
    } do
      conn =
        post(conn, Routes.assets_path(conn, :create), %{
          blockchain: blockchain_name,
          address: address,
          signature: signature,
          asset_code: asset_code,
          supply: asset_supply
        })

      string_supply = Integer.to_string(asset_supply)

      %{
        "data" => %{
          "id" => _id,
          "code" => ^asset_code,
          "supply" => ^string_supply
        },
        "status" => 201
      } = json_response(conn, 201)
    end

    test "with missing params", %{
      authenticated_conn: conn
    } do
      conn = post(conn, Routes.assets_path(conn, :create), %{})

      %{
        "code" => "bad_request",
        "detail" => "The body params are invalid",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when supply isn't a valid number", %{
      authenticated_conn: conn,
      blockchain: %{name: blockchain_name},
      account: %{address: address, signature: signature},
      asset_code: asset_code
    } do
      conn =
        post(conn, Routes.assets_path(conn, :create), %{
          blockchain: blockchain_name,
          address: address,
          signature: signature,
          asset_code: asset_code,
          supply: "33,22"
        })

      %{
        "code" => "invalid_supply_format",
        "detail" => "The introduced supply format is invalid",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when blockchain is not valid", %{
      authenticated_conn: conn,
      account: %{address: address, signature: signature},
      asset_code: asset_code,
      asset_supply: asset_supply
    } do
      conn =
        post(conn, Routes.assets_path(conn, :create), %{
          blockchain: "invalid",
          address: address,
          signature: signature,
          asset_code: asset_code,
          supply: asset_supply
        })

      %{
        "code" => "blockchain_not_found",
        "detail" => "The introduced blockchain doesn't exist",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when account address doesn't exist", %{
      authenticated_conn: conn,
      not_existing_account: not_existing_account,
      signature: signature,
      blockchain: %{name: blockchain_name},
      asset_code: asset_code,
      asset_supply: asset_supply
    } do
      conn =
        post(conn, Routes.assets_path(conn, :create), %{
          blockchain: blockchain_name,
          address: not_existing_account,
          signature: signature,
          asset_code: asset_code,
          supply: asset_supply
        })

      %{
        "code" => "wallet_not_found",
        "detail" =>
          "The introduced address doesn't exist or doesn't have associated the blockchain",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when signature is invalid", %{
      authenticated_conn: conn,
      account: %{address: address},
      blockchain: %{name: blockchain_name},
      invalid_signature: invalid_signature,
      asset_code: asset_code,
      asset_supply: asset_supply
    } do
      conn =
        post(conn, Routes.assets_path(conn, :create), %{
          blockchain: blockchain_name,
          address: address,
          signature: invalid_signature,
          asset_code: asset_code,
          supply: asset_supply
        })

      %{
        "code" => "decoding_error",
        "detail" => "The signature is invalid",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when asset is invalid", %{
      authenticated_conn: conn,
      account: %{address: address},
      blockchain: %{name: blockchain_name},
      signature: signature,
      asset_supply: asset_supply
    } do
      conn =
        post(conn, Routes.assets_path(conn, :create), %{
          blockchain: blockchain_name,
          address: address,
          signature: signature,
          asset_code: "GGF&A",
          supply: asset_supply
        })

      %{
        "code" => "unprocessable_entity",
        "detail" => %{"code" => ["code must be alphanumeric"]},
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when authenticate token is invalid", %{
      invalid_authenticated_conn: conn,
      account: %{address: address, signature: signature},
      blockchain: %{name: blockchain_name},
      asset_code: asset_code,
      asset_supply: asset_supply
    } do
      conn =
        post(conn, Routes.assets_path(conn, :create), %{
          blockchain: blockchain_name,
          address: address,
          signature: signature,
          asset_code: asset_code,
          supply: asset_supply
        })

      %{
        "code" => 401,
        "detail" => "Invalid authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end

    test "when authenticate token is not submit", %{
      unauthenticated_conn: conn,
      account: %{address: address, signature: signature},
      blockchain: %{name: blockchain_name},
      asset_code: asset_code,
      asset_supply: asset_supply
    } do
      conn =
        post(conn, Routes.assets_path(conn, :create), %{
          blockchain: blockchain_name,
          address: address,
          signature: signature,
          asset_code: asset_code,
          supply: asset_supply
        })

      %{
        "code" => 401,
        "detail" => "Missing authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end
  end

  describe "show" do
    setup [:create_asset]

    test "when asset id exist", %{
      authenticated_conn: conn,
      asset: %{id: asset_id, code: code, supply: supply}
    } do
      conn = get(conn, Routes.assets_path(conn, :show, asset_id))

      %{
        "data" => %{
          "id" => ^asset_id,
          "code" => ^code,
          "supply" => ^supply
        },
        "status" => 200
      } = json_response(conn, 200)
    end

    test "when asset id doesn't exist", %{
      authenticated_conn: conn,
      not_existing_id: not_existing_id
    } do
      conn = get(conn, Routes.assets_path(conn, :show, not_existing_id))

      %{
        "code" => "asset_not_found",
        "detail" => "The introduced asset doesn't exist",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when asset id is invalid", %{
      authenticated_conn: conn,
      invalid_asset_id: invalid_asset_id
    } do
      conn = get(conn, Routes.assets_path(conn, :show, invalid_asset_id))

      %{
        "code" => "asset_not_found",
        "detail" => "The introduced asset doesn't exist",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when authenticate token is invalid", %{
      invalid_authenticated_conn: conn,
      asset: %{id: asset_id}
    } do
      conn = get(conn, Routes.assets_path(conn, :show, asset_id))

      %{
        "code" => 401,
        "detail" => "Invalid authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end

    test "when authenticate token is not submit", %{
      unauthenticated_conn: conn,
      asset: %{id: asset_id}
    } do
      conn = get(conn, Routes.assets_path(conn, :show, asset_id))

      %{
        "code" => 401,
        "detail" => "Missing authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end
  end

  describe "show_issuer/2" do
    setup [:create_asset]

    test "when asset id exist", %{
      authenticated_conn: conn,
      asset: %{id: asset_id},
      minter_account: %{address: address}
    } do
      conn = get(conn, Routes.assets_path(conn, :show_issuer, asset_id))

      %{
        "data" => %{
          "address" => ^address
        },
        "status" => 200
      } = json_response(conn, 200)
    end

    test "when asset id doesn't exist", %{
      authenticated_conn: conn,
      not_existing_id: not_existing_id
    } do
      conn = get(conn, Routes.assets_path(conn, :show_issuer, not_existing_id))

      %{
        "code" => "asset_not_found",
        "detail" => "The introduced asset doesn't exist",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when asset id is invalid", %{
      authenticated_conn: conn,
      invalid_asset_id: invalid_asset_id
    } do
      conn = get(conn, Routes.assets_path(conn, :show_issuer, invalid_asset_id))

      %{
        "code" => "asset_not_found",
        "detail" => "The introduced asset doesn't exist",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when authenticate token is invalid", %{
      invalid_authenticated_conn: conn,
      asset: %{id: asset_id}
    } do
      conn = get(conn, Routes.assets_path(conn, :show_issuer, asset_id))

      %{
        "code" => 401,
        "detail" => "Invalid authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end

    test "when authenticate token is not submit", %{
      unauthenticated_conn: conn,
      asset: %{id: asset_id}
    } do
      conn = get(conn, Routes.assets_path(conn, :show_issuer, asset_id))

      %{
        "code" => 401,
        "detail" => "Missing authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end
  end

  describe "show_accounts/2" do
    setup [:create_asset]

    test "when asset id exist", %{
      authenticated_conn: conn,
      asset: %{id: asset_id},
      minter_account: %{address: address}
    } do
      conn = get(conn, Routes.assets_path(conn, :show_accounts, asset_id))

      %{
        "data" => %{
          "addresses" => [^address]
        },
        "status" => 200
      } = json_response(conn, 200)
    end

    test "when asset id doesn't exist", %{
      authenticated_conn: conn,
      not_existing_id: not_existing_id
    } do
      conn = get(conn, Routes.assets_path(conn, :show_accounts, not_existing_id))

      %{
        "code" => "asset_not_found",
        "detail" => "The introduced asset doesn't exist",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when asset id is invalid", %{
      authenticated_conn: conn,
      invalid_asset_id: invalid_asset_id
    } do
      conn = get(conn, Routes.assets_path(conn, :show_accounts, invalid_asset_id))

      %{
        "code" => "asset_not_found",
        "detail" => "The introduced asset doesn't exist",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when authenticate token is invalid", %{
      invalid_authenticated_conn: conn,
      asset: %{id: asset_id}
    } do
      conn = get(conn, Routes.assets_path(conn, :show_accounts, asset_id))

      %{
        "code" => 401,
        "detail" => "Invalid authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end

    test "when authenticate token is not submit", %{
      unauthenticated_conn: conn,
      asset: %{id: asset_id}
    } do
      conn = get(conn, Routes.assets_path(conn, :show_accounts, asset_id))

      %{
        "code" => 401,
        "detail" => "Missing authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end
  end

  defp create_asset(_context) do
    %{asset: asset, account: minter_account} = insert(:asset_holder)

    %{
      asset: asset,
      not_existing_id: "d9cb83d6-05f5-4557-b5d0-9e1728c42091",
      invalid_asset_id: "123",
      minter_account: minter_account
    }
  end
end
