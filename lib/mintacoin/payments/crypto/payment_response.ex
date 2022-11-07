defmodule Mintacoin.Payments.Crypto.PaymentResponse do
  @moduledoc """
  This struct defines the normalized response of a transaction when a payment is created in a blockchain
  """

  @type t :: %__MODULE__{
          successful: boolean(),
          tx_id: String.t(),
          tx_hash: String.t(),
          tx_timestamp: String.t(),
          tx_response: map()
        }

  defstruct [:successful, :tx_id, :tx_hash, :tx_timestamp, :tx_response]
end
