defmodule Mintacoin.Payments.Stellar do
  @moduledoc """
  Implementation of the stellar crypto functions for payments.
  """

  @behaviour Mintacoin.Payments.Crypto.Spec

  alias Mintacoin.Payments.Crypto.PaymentResponse
  alias Stellar.{Horizon, Horizon.Transaction, Horizon.Transactions, KeyPair, TxBuild}
  alias Stellar.TxBuild.Payment

  @type account_information :: map()
  @type amount :: integer() | float()
  @type asset :: list()
  @type envelope :: {:ok, String.t()} | {:error, atom()}
  @type format_response :: {:ok, PaymentResponse.t()} | {:error, any()}
  @type key :: String.t()
  @type operations :: list()
  @type payment :: Payment.t()
  @type sequence_number :: struct()
  @type signatures :: list()
  @type tx_response :: {:ok | :error, map()}

  @impl true
  def create_payment(opts) do
    source_secret_key = Keyword.get(opts, :source_secret_key)
    destination_public_key = Keyword.get(opts, :destination_public_key)
    amount = Keyword.get(opts, :amount)
    asset_code = Keyword.get(opts, :asset_code)

    %{
      public_key: master_pk,
      signature: master_signature
    } = master_account_information()

    %{
      public_key: source_public_key,
      signature: source_signature
    } = account_information(source_secret_key)

    asset = [code: asset_code, issuer: master_pk]
    signatures = [master_signature, source_signature]

    destination_public_key
    |> build_payment_operation(source_public_key, asset, amount)
    |> build_envelope(master_pk, signatures)
    |> execute_transaction()
  end

  @spec account_information(secret_key :: key()) :: account_information()
  defp account_information(secret_key) do
    {pk, _sk} = account_keypair = KeyPair.from_secret_seed(secret_key)
    signature = TxBuild.Signature.new(account_keypair)

    %{
      public_key: pk,
      signature: signature
    }
  end

  @spec master_account_information() :: account_information()
  defp master_account_information, do: master_account_secret_key() |> account_information()

  @spec master_account_secret_key() :: key()
  defp master_account_secret_key, do: Application.get_env(:mintacoin, :stellar_fund_secret_key)

  @spec build_payment_operation(
          destination_public_key :: key(),
          source_public_key :: key(),
          asset :: asset(),
          amount :: amount()
        ) :: list()
  defp build_payment_operation(destination_public_key, source_public_key, asset, amount),
    do: [payment_operation(destination_public_key, source_public_key, asset, amount)]

  @spec payment_operation(
          destination_public_key :: key(),
          source_public_key :: key(),
          asset :: asset(),
          amount :: amount()
        ) :: payment()
  defp payment_operation(destination_public_key, source_public_key, asset, amount) do
    Payment.new(
      destination: destination_public_key,
      asset: asset,
      amount: amount,
      source_account: source_public_key
    )
  end

  @spec build_envelope(
          operations :: operations(),
          source_public_key :: key(),
          signatures :: signatures()
        ) ::
          envelope()
  defp build_envelope(operations, source_public_key, signatures) do
    sequence_number = get_sequence_number(source_public_key)

    source_public_key
    |> TxBuild.Account.new()
    |> Stellar.TxBuild.new(sequence_number: sequence_number)
    |> TxBuild.add_operations(operations)
    |> TxBuild.sign(signatures)
    |> TxBuild.envelope()
  end

  @spec get_sequence_number(public_key :: key()) :: sequence_number()
  defp get_sequence_number(public_key) do
    {:ok, seq_num} = Horizon.Accounts.fetch_next_sequence_number(public_key)
    TxBuild.SequenceNumber.new(seq_num)
  end

  @spec execute_transaction(envelope :: envelope()) :: format_response()
  defp execute_transaction({:ok, envelop}) do
    envelop
    |> Transactions.create()
    |> format_response()
  end

  @spec format_response(tx_response :: tx_response()) :: format_response()
  defp format_response(
         {:ok,
          %Transaction{id: id, successful: successful, hash: hash, created_at: created_at} =
            tx_response}
       ) do
    {:ok,
     %PaymentResponse{
       successful: successful,
       tx_id: id,
       tx_hash: hash,
       tx_timestamp: DateTime.to_string(created_at),
       tx_response: Map.from_struct(tx_response)
     }}
  end

  defp format_response({:error, response}), do: {:error, response}
end
