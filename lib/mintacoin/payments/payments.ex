defmodule Mintacoin.Payments do
  @moduledoc """
  This module is the responsible for the CRUD operations for payment
  """

  import Ecto.Query

  alias Ecto.{Changeset, UUID}
  alias Mintacoin.{Account, Payment, Repo}

  @type address :: String.t()
  @type error :: Changeset.t()
  @type id :: UUID.t()
  @type params :: map()
  @type payment :: Payment.t()
  @type payments :: list(payment) | []

  @spec create(params :: params()) :: {:ok, payment()} | {:error, error()}
  def create(params) do
    %Payment{}
    |> Payment.create_changeset(params)
    |> Repo.insert()
  end

  @spec update(payment_id :: id(), changes :: params()) :: {:ok, payment()} | {:error, error()}
  def update(id, changes) do
    Payment
    |> Repo.get(id)
    |> Payment.changeset(changes)
    |> Repo.update()
  end

  @spec retrieve_by_id(id :: id()) :: {:ok, payment() | nil}
  def retrieve_by_id(id), do: {:ok, Repo.get(Payment, id)}

  @spec retrieve_outgoing_payments_by_address(address :: address()) :: {:ok, payments()}
  def retrieve_outgoing_payments_by_address(address) do
    query =
      from(payment in Payment,
        join: account in Account,
        on: payment.source_account_id == account.id,
        where: account.address == ^address
      )

    {:ok, Repo.all(query)}
  end

  @spec retrieve_incoming_payments_by_address(address :: address()) :: {:ok, payments()}
  def retrieve_incoming_payments_by_address(address) do
    query =
      from(payment in Payment,
        join: account in Account,
        on: payment.destination_account_id == account.id,
        where: account.address == ^address
      )

    {:ok, Repo.all(query)}
  end
end
