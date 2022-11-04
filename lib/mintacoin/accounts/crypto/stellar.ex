defmodule Mintacoin.Accounts.Stellar do
  @moduledoc """
  Implementation of the Stellar crypto functions for accounts
  """

  alias Mintacoin.Accounts.Crypto.AccountResponse
  alias Stellar.{Horizon, Horizon.Transaction, KeyPair, TxBuild}
  alias Stellar.TxBuild.{CreateAccount, SequenceNumber, Signature}

  @type create_account :: CreateAccount.t()
  @type envelope :: String.t()
  @type error :: {:error, any()}
  @type funder_account_information :: map()
  @type key_pair :: {public_key(), secret_key()}
  @type impl_response :: {:ok, AccountResponse.t()} | error()
  @type public_key :: String.t()
  @type secret_key :: String.t()
  @type sequence_number :: SequenceNumber.t()
  @type signature :: Signature.t()
  @type status :: :ok | :error
  @type stellar_response :: map()
  @type tx_envelope :: {:ok, envelope()} | {:error, atom()}

  @behaviour Mintacoin.Accounts.Crypto.Spec

  @starting_balance Application.compile_env!(:mintacoin, :starting_balance)

  @impl true
  def create_account(_opts) do
    {public_key, secret_key} = KeyPair.random()

    %{funder_public_key: funder_public_key, funder_signature: funder_signature} =
      funder_account_information()

    public_key
    |> build_create_account_operation()
    |> build_envelope(funder_public_key, funder_signature)
    |> execute_transaction(public_key, secret_key)
  end

  @spec funder_account_information() :: funder_account_information()
  defp funder_account_information do
    {funder_public_key, _fund_private_key} = funder_keypair = funder_key_pair_from_system()
    funder_signature = Signature.new(funder_keypair)

    %{funder_public_key: funder_public_key, funder_signature: funder_signature}
  end

  @spec build_create_account_operation(destination :: public_key()) ::
          create_account()
  defp build_create_account_operation(destination) do
    starting_balance = String.to_float(@starting_balance)

    CreateAccount.new(
      destination: destination,
      starting_balance: starting_balance
    )
  end

  @spec build_envelope(
          operation :: create_account(),
          funder_public_key :: public_key(),
          signature :: signature()
        ) ::
          tx_envelope()
  defp build_envelope(operation, funder_public_key, signature) do
    sequence_number = get_sequence_number(funder_public_key)

    funder_public_key
    |> TxBuild.Account.new()
    |> TxBuild.new(sequence_number: sequence_number)
    |> TxBuild.add_operation(operation)
    |> TxBuild.sign(signature)
    |> TxBuild.envelope()
  end

  @spec get_sequence_number(funder_public_key :: public_key()) ::
          sequence_number()
  defp get_sequence_number(funder_public_key) do
    {:ok, sequence} = Horizon.Accounts.fetch_next_sequence_number(funder_public_key)
    SequenceNumber.new(sequence)
  end

  @spec execute_transaction(
          tx_envelope :: tx_envelope(),
          public_key :: public_key(),
          secret_key :: secret_key()
        ) ::
          impl_response()
  defp execute_transaction({:ok, envelope}, public_key, secret_key) do
    envelope
    |> Horizon.Transactions.create()
    |> format_response(public_key, secret_key)
  end

  @spec funder_key_pair_from_system() :: key_pair()
  defp funder_key_pair_from_system do
    Application.get_env(:mintacoin, :stellar_fund_secret_key, nil)
    |> KeyPair.from_secret_seed()
  end

  @spec format_response(
          {status(), stellar_response()},
          public_key :: secret_key(),
          secret_key :: secret_key()
        ) :: impl_response()
  defp format_response(
         {:ok,
          %Transaction{id: id, successful: successful, hash: hash, created_at: created_at} =
            tx_response},
         public_key,
         secret_key
       ) do
    {:ok,
     %AccountResponse{
       public_key: public_key,
       secret_key: secret_key,
       successful: successful,
       tx_id: id,
       tx_hash: hash,
       tx_timestamp: DateTime.to_string(created_at),
       tx_response: Map.from_struct(tx_response)
     }}
  end

  defp format_response({:error, response}, _public_key, _secret_key), do: {:error, response}
end
