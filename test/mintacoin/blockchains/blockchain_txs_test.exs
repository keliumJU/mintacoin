defmodule Mintacoin.Blockchains.BlockchainTxsTest do
  @moduledoc """
    This module is used to group common tests for Blockchain transaction functions
  """
  use Mintacoin.DataCase, async: false

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.Changeset
  alias Mintacoin.{BlockchainTx, BlockchainTxs}

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    account = insert(:account)
    blockchain = insert(:blockchain, %{name: "stellar", network: "mainnet"})
    wallet = insert(:wallet, %{blockchain: blockchain})
    asset = insert(:asset)
    payment = insert(:payment)

    asset_holder =
      insert(:asset_holder, %{
        account: account,
        blockchain: blockchain,
        asset: asset,
        wallet: wallet
      })

    blockchain_tx =
      insert(:blockchain_tx, %{wallet: wallet, blockchain: blockchain, account: account})

    %{
      account: account,
      wallet: wallet,
      blockchain: blockchain,
      asset: asset,
      asset_holder: asset_holder,
      payment: payment,
      blockchain_tx: blockchain_tx,
      tx_id: "7f82fe6ac195e7674f7bdf7a3416683ffd55c8414978c70bf4da08ac64fea129",
      tx_hash: "7f82fe6ac195e7674f7bdf7a3416683ffd55c8414978c70bf4da08ac64fea129",
      tx_timestamp: "~U[2022-06-29 15:45:45Z]",
      successful: true,
      tx_response: %{successful: true},
      not_found_uuid: "d9cb83d6-05f5-4557-b5d0-9e1728c42091"
    }
  end

  describe "create/1" do
    test "with all valid params", %{
      wallet: %{id: wallet_id},
      blockchain: %{id: blockchain_id},
      asset: %{id: asset_id},
      asset_holder: %{id: asset_holder_id},
      payment: %{id: payment_id},
      tx_id: tx_id,
      tx_hash: tx_hash,
      tx_timestamp: tx_timestamp,
      tx_response: tx_response
    } do
      {:ok,
       %BlockchainTx{
         wallet_id: ^wallet_id,
         blockchain_id: ^blockchain_id,
         asset_id: ^asset_id,
         asset_holder_id: ^asset_holder_id,
         payment_id: ^payment_id,
         tx_id: ^tx_id,
         tx_hash: ^tx_hash,
         tx_timestamp: ^tx_timestamp,
         tx_response: ^tx_response
       }} =
        BlockchainTxs.create(%{
          wallet_id: wallet_id,
          blockchain_id: blockchain_id,
          asset_id: asset_id,
          asset_holder_id: asset_holder_id,
          payment_id: payment_id,
          tx_id: tx_id,
          tx_hash: tx_hash,
          tx_timestamp: tx_timestamp,
          tx_response: tx_response
        })
    end

    test "with minimal valid params", %{
      wallet: %{id: wallet_id},
      blockchain: %{id: blockchain_id}
    } do
      {:ok,
       %BlockchainTx{
         wallet_id: ^wallet_id,
         blockchain_id: ^blockchain_id
       }} =
        BlockchainTxs.create(%{
          wallet_id: wallet_id,
          blockchain_id: blockchain_id
        })
    end

    test "with missing param" do
      {:error,
       %Changeset{
         errors: [
           blockchain_id: {"can't be blank", _}
         ]
       }} = BlockchainTxs.create(%{})
    end

    test "when blockchain doesn't exist", %{
      wallet: %{id: wallet_id},
      not_found_uuid: not_found_uuid
    } do
      {:error,
       %Changeset{
         errors: [
           {:blockchain_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        BlockchainTxs.create(%{
          wallet_id: wallet_id,
          blockchain_id: not_found_uuid
        })
    end

    test "when wallet_id doesn't exist", %{
      not_found_uuid: not_found_uuid,
      blockchain: %{id: blockchain_id}
    } do
      {:error,
       %Changeset{
         errors: [
           {:wallet_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        BlockchainTxs.create(%{
          wallet_id: not_found_uuid,
          blockchain_id: blockchain_id
        })
    end

    test "when asset_id doesn't exist", %{
      not_found_uuid: not_found_uuid,
      blockchain: %{id: blockchain_id}
    } do
      {:error,
       %Changeset{
         errors: [
           {:asset_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        BlockchainTxs.create(%{
          asset_id: not_found_uuid,
          blockchain_id: blockchain_id
        })
    end

    test "when asset_holder_id doesn't exist", %{
      not_found_uuid: not_found_uuid,
      blockchain: %{id: blockchain_id}
    } do
      {:error,
       %Changeset{
         errors: [
           {:asset_holder_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        BlockchainTxs.create(%{
          asset_holder_id: not_found_uuid,
          blockchain_id: blockchain_id
        })
    end

    test "when payment_id doesn't exist", %{
      not_found_uuid: not_found_uuid,
      blockchain: %{id: blockchain_id}
    } do
      {:error,
       %Changeset{
         errors: [
           {:payment_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        BlockchainTxs.create(%{
          payment_id: not_found_uuid,
          blockchain_id: blockchain_id
        })
    end
  end

  describe "update/2" do
    test "when blockchainTx exists and is updated with valid params", %{
      blockchain_tx: %{id: blockchain_tx_id},
      tx_id: tx_id,
      tx_hash: tx_hash,
      successful: successful,
      tx_timestamp: tx_timestamp,
      tx_response: tx_response
    } do
      {:ok,
       %BlockchainTx{
         tx_id: ^tx_id,
         tx_hash: ^tx_hash,
         successful: ^successful,
         tx_timestamp: ^tx_timestamp,
         tx_response: ^tx_response
       }} =
        BlockchainTxs.update(blockchain_tx_id, %{
          tx_id: tx_id,
          tx_hash: tx_hash,
          successful: successful,
          tx_timestamp: tx_timestamp,
          tx_response: tx_response
        })
    end
  end

  describe "retrieve_by_id/1" do
    test "when blockchain tx exist", %{blockchain_tx: %{id: blockchain_tx_id}} do
      {:ok, %BlockchainTx{id: ^blockchain_tx_id}} = BlockchainTxs.retrieve_by_id(blockchain_tx_id)
    end

    test "when a blockchain tx doesn't exist", %{not_found_uuid: not_found_uuid} do
      {:ok, nil} = BlockchainTxs.retrieve_by_id(not_found_uuid)
    end
  end

  describe "retrieve_by_tx_id/1" do
    test "with valid tx_id", %{blockchain_tx: %{id: blockchain_tx_id, tx_id: tx_id}} do
      {:ok, %{id: ^blockchain_tx_id, tx_id: ^tx_id}} = BlockchainTxs.retrieve_by_tx_id(tx_id)
    end

    test "with invalid tx_id" do
      {:ok, nil} = BlockchainTxs.retrieve_by_tx_id("invalid_tx_id")
    end
  end

  describe "retrieve_by_wallet_id/1" do
    test "with valid wallet id", %{
      blockchain_tx: %{id: blockchain_tx_id, wallet: %{id: wallet_id}}
    } do
      {:ok, [%{id: ^blockchain_tx_id}]} = BlockchainTxs.retrieve_by_wallet_id(wallet_id)
    end

    test "when wallet doesn't exist", %{not_found_uuid: not_found_uuid} do
      {:ok, []} = BlockchainTxs.retrieve_by_wallet_id(not_found_uuid)
    end
  end

  describe "retrieve_by_account_id/1" do
    test "with valid account id", %{
      blockchain_tx: %{id: blockchain_tx_id, account: %{id: account}}
    } do
      {:ok, [%{id: ^blockchain_tx_id}]} = BlockchainTxs.retrieve_by_account_id(account)
    end

    test "when account doesn't exist", %{not_found_uuid: not_found_uuid} do
      {:ok, []} = BlockchainTxs.retrieve_by_account_id(not_found_uuid)
    end
  end

  describe "retrieve_by_asset_id/1" do
    test "with valid asset id", %{
      blockchain_tx: %{id: blockchain_tx_id, asset_id: asset_id}
    } do
      {:ok, [%{id: ^blockchain_tx_id}]} = BlockchainTxs.retrieve_by_asset_id(asset_id)
    end

    test "when asset doesn't exist", %{not_found_uuid: not_found_uuid} do
      {:ok, []} = BlockchainTxs.retrieve_by_asset_id(not_found_uuid)
    end
  end

  describe "retrieve_by_asset_holder_id/1" do
    test "with valid asset_holder_id", %{
      blockchain_tx: %{id: blockchain_tx_id, asset_holder_id: asset_holder_id}
    } do
      {:ok, [%{id: ^blockchain_tx_id}]} =
        BlockchainTxs.retrieve_by_asset_holder_id(asset_holder_id)
    end

    test "when asset_holder_id doesn't exist", %{not_found_uuid: not_found_uuid} do
      {:ok, []} = BlockchainTxs.retrieve_by_asset_holder_id(not_found_uuid)
    end
  end

  describe "retrieve_by_payment_id/1" do
    test "with valid asset_holder_id", %{
      blockchain_tx: %{id: blockchain_tx_id, payment_id: payment_id}
    } do
      {:ok, [%{id: ^blockchain_tx_id}]} = BlockchainTxs.retrieve_by_payment_id(payment_id)
    end

    test "when asset_holder_id doesn't exist", %{not_found_uuid: not_found_uuid} do
      {:ok, []} = BlockchainTxs.retrieve_by_payment_id(not_found_uuid)
    end
  end
end
