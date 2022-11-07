defmodule Mintacoin.Payments.StellarTest do
  @moduledoc """
  This module is used to test functionalities of the Stellar crypto implementation
  """
  use Mintacoin.DataCase, async: false

  alias Mintacoin.Payments.{Crypto.PaymentResponse, StellarMock}

  describe "create_payment/1" do
    test "with an existing blockchain" do
      {
        :ok,
        %PaymentResponse{
          tx_id: "200dbe2ed52eb76bb850a842494ef47e9b266426e6a8326e9309ec1ed66af3d9",
          tx_hash: "200dbe2ed52eb76bb850a842494ef47e9b266426e6a8326e9309ec1ed66af3d9"
        }
      } = StellarMock.create_payment([])
    end
  end
end
