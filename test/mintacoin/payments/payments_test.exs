defmodule Mintacoin.Payments.PaymentsTest do
  @moduledoc """
  This module is used to group common tests for Payments functions
  """
  use Mintacoin.DataCase, async: false

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.Changeset
  alias Mintacoin.{Payment, Payments}

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    blockchain = insert(:blockchain)
    asset = insert(:asset)
    source_account = insert(:account)
    destination_account = insert(:account)
    amount = "734.345667"
    status = :processing
    new_status = :completed
    successful = false
    new_successful = true

    payment =
      insert(:payment, %{source_account: source_account, destination_account: destination_account})

    %{
      payment: payment,
      blockchain: blockchain,
      asset: asset,
      source_account: source_account,
      destination_account: destination_account,
      amount: amount,
      status: status,
      new_status: new_status,
      successful: successful,
      new_successful: new_successful,
      not_existing_uuid: "d9cb83d6-05f5-4557-b5d0-9e1728c42091"
    }
  end

  describe "create/1" do
    test "with valid params", %{
      blockchain: %{id: blockchain_id},
      asset: %{id: asset_id},
      source_account: %{id: source_account_id},
      destination_account: %{id: destination_account_id},
      amount: amount,
      status: status,
      successful: successful
    } do
      {:ok,
       %Payment{
         blockchain_id: ^blockchain_id,
         source_account_id: ^source_account_id,
         destination_account_id: ^destination_account_id,
         asset_id: ^asset_id,
         amount: ^amount,
         status: ^status,
         successful: ^successful
       }} =
        Payments.create(%{
          blockchain_id: blockchain_id,
          source_account_id: source_account_id,
          destination_account_id: destination_account_id,
          asset_id: asset_id,
          amount: amount,
          status: status,
          successful: successful
        })
    end

    test "with missing params" do
      {:error,
       %Changeset{
         errors: [
           blockchain_id: {"can't be blank", _},
           source_account_id: {"can't be blank", _},
           destination_account_id: {"can't be blank", _},
           asset_id: {"can't be blank", _},
           amount: {"can't be blank", _},
           successful: {"can't be blank", _}
         ]
       }} = Payments.create(%{})
    end

    test "with invalid status", %{
      blockchain: %{id: blockchain_id},
      asset: %{id: asset_id},
      source_account: %{id: source_account_id},
      destination_account: %{id: destination_account_id},
      amount: amount,
      successful: successful
    } do
      {:error,
       %Changeset{
         errors: [
           {:status, {"is invalid", _detail}}
           | _tail
         ]
       }} =
        Payments.create(%{
          blockchain_id: blockchain_id,
          source_account_id: source_account_id,
          destination_account_id: destination_account_id,
          asset_id: asset_id,
          amount: amount,
          status: :invalid,
          successful: successful
        })
    end

    test "when blockchain_id doesn't exist", %{
      asset: %{id: asset_id},
      source_account: %{id: source_account_id},
      destination_account: %{id: destination_account_id},
      amount: amount,
      status: status,
      successful: successful,
      not_existing_uuid: not_existing_uuid
    } do
      {:error,
       %Changeset{
         errors: [
           {:blockchain_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        Payments.create(%{
          blockchain_id: not_existing_uuid,
          source_account_id: source_account_id,
          destination_account_id: destination_account_id,
          asset_id: asset_id,
          amount: amount,
          status: status,
          successful: successful
        })
    end

    test "when source_account_id doesn't exist", %{
      blockchain: %{id: blockchain_id},
      asset: %{id: asset_id},
      destination_account: %{id: destination_account_id},
      amount: amount,
      status: status,
      successful: successful,
      not_existing_uuid: not_existing_uuid
    } do
      {:error,
       %Changeset{
         errors: [
           {:source_account_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        Payments.create(%{
          blockchain_id: blockchain_id,
          source_account_id: not_existing_uuid,
          destination_account_id: destination_account_id,
          asset_id: asset_id,
          amount: amount,
          status: status,
          successful: successful
        })
    end

    test "when destination_account doesn't exist", %{
      blockchain: %{id: blockchain_id},
      asset: %{id: asset_id},
      source_account: %{id: source_account_id},
      amount: amount,
      status: status,
      successful: successful,
      not_existing_uuid: not_existing_uuid
    } do
      {:error,
       %Changeset{
         errors: [
           {:destination_account_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        Payments.create(%{
          blockchain_id: blockchain_id,
          source_account_id: source_account_id,
          destination_account_id: not_existing_uuid,
          asset_id: asset_id,
          amount: amount,
          status: status,
          successful: successful
        })
    end

    test "when asset_id doesn't exist", %{
      blockchain: %{id: blockchain_id},
      source_account: %{id: source_account_id},
      destination_account: %{id: destination_account_id},
      amount: amount,
      status: status,
      successful: successful,
      not_existing_uuid: not_existing_uuid
    } do
      {:error,
       %Changeset{
         errors: [
           {:asset_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        Payments.create(%{
          blockchain_id: blockchain_id,
          source_account_id: source_account_id,
          destination_account_id: destination_account_id,
          asset_id: not_existing_uuid,
          amount: amount,
          status: status,
          successful: successful
        })
    end
  end

  describe "update/2" do
    test "with valid params", %{
      payment: %{id: payment_id},
      new_status: new_status,
      new_successful: new_successful
    } do
      {:ok, %Payment{id: ^payment_id, status: ^new_status, successful: ^new_successful}} =
        Payments.update(payment_id, %{status: new_status, successful: new_successful})
    end

    test "with invalid status", %{payment: %{id: payment_id}} do
      {:error,
       %Changeset{
         errors: [
           {:status, {"is invalid", _detail}}
           | _tail
         ]
       }} = Payments.update(payment_id, %{status: :invalid})
    end
  end

  describe "retrieve_by_id/1" do
    test "when payment exist", %{payment: %{id: payment_id}} do
      {:ok, %Payment{id: ^payment_id}} = Payments.retrieve_by_id(payment_id)
    end

    test "when payment doesn't exist", %{not_existing_uuid: not_existing_uuid} do
      {:ok, nil} = Payments.retrieve_by_id(not_existing_uuid)
    end
  end

  describe "retrieve_outgoing_payments_by_address/1" do
    test "when address exist", %{source_account: %{id: source_account_id, address: address}} do
      {:ok, [%Payment{source_account_id: ^source_account_id}]} =
        Payments.retrieve_outgoing_payments_by_address(address)
    end

    test "when address doesn't exist" do
      {:ok, []} = Payments.retrieve_outgoing_payments_by_address("address")
    end
  end

  describe "retrieve_incoming_payments_by_address/1" do
    test "when address exist", %{
      destination_account: %{id: destination_account_id, address: address}
    } do
      {:ok, [%Payment{destination_account_id: ^destination_account_id}]} =
        Payments.retrieve_incoming_payments_by_address(address)
    end

    test "when address doesn't exist" do
      {:ok, []} = Payments.retrieve_incoming_payments_by_address("address")
    end
  end
end
