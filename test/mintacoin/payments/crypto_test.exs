defmodule Mintacoin.Payments.CryptoTest do
  @moduledoc """
  This module is used to test the payment crypto calls for the different blockchains
  """
  use Mintacoin.DataCase, async: false

  alias Mintacoin.Payments.{Crypto, Crypto.PaymentResponse, StellarMock}

  setup do
    Application.put_env(:mintacoin, :crypto_impl, StellarMock)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :crypto_impl)
    end)
  end

  describe "create_payment/1" do
    test "with the stellar blockchain" do
      {:ok,
       %PaymentResponse{
         tx_id: "200dbe2ed52eb76bb850a842494ef47e9b266426e6a8326e9309ec1ed66af3d9",
         tx_hash: "200dbe2ed52eb76bb850a842494ef47e9b266426e6a8326e9309ec1ed66af3d9"
       }} = Crypto.create_payment()
    end
  end
end
