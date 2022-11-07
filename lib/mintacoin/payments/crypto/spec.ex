defmodule Mintacoin.Payments.Crypto.Spec do
  @moduledoc """
  Defines contracts for the transactions available for payments crypto
  """

  alias Mintacoin.Payments.Crypto.PaymentResponse

  @type opts :: Keyword.t()
  @type response :: {:ok, PaymentResponse.t()} | {:error, map()}

  @callback create_payment(opts()) :: response()
end
