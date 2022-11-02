defmodule Mintacoin.PaymentFactory do
  @moduledoc """
  Allow the creation of payment while testing.
  """

  alias Ecto.UUID
  alias Mintacoin.Payment

  defmacro __using__(_opts) do
    quote do
      @spec payment_factory(attrs :: map()) :: Payment.t()
      def payment_factory(attrs) do
        blockchain = Map.get(attrs, :blockchain, insert(:blockchain))
        asset = Map.get(attrs, :asset, insert(:asset))
        source_account = Map.get(attrs, :source_account, insert(:account))
        destination_account = Map.get(attrs, :destination_account, insert(:account))
        amount = Map.get(attrs, :amount, "123.43544")
        status = Map.get(attrs, :status, :completed)
        successful = Map.get(attrs, :successful, true)

        %Payment{
          id: UUID.generate(),
          blockchain: blockchain,
          asset: asset,
          source_account: source_account,
          destination_account: destination_account,
          amount: amount,
          status: status,
          successful: successful
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
