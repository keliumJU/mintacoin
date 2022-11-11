defmodule MintacoinWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use MintacoinWeb, :controller

  alias Ecto.Changeset
  alias MintacoinWeb.{ChangesetView, ErrorView}

  @type conn :: Plug.Conn.t()
  @type error :: :not_found | :bad_request | map() | Changeset.t()

  @error_templates [
    not_found: {404, "Resource not found"},
    bad_request: {400, "The body params are invalid"},
    blockchain_not_found: {400, "The introduced blockchain doesn't exist"},
    decoding_error: {400, "The signature is invalid"},
    invalid_address: {400, "The address is invalid"},
    invalid_seed_words: {400, "The seed words are invalid"},
    asset_not_found: {400, "The introduced asset doesn't exist"},
    wallet_not_found:
      {400, "The introduced address doesn't exist or doesn't have associated the blockchain"},
    invalid_supply_format: {400, "The introduced supply format is invalid"}
  ]

  # This clause handles errors returned by Ecto's insert/update/delete.
  @spec call(conn :: conn(), {:error, error()}) :: conn()
  def call(conn, {:error, %Changeset{} = changeset}) do
    conn
    |> put_status(:bad_request)
    |> put_view(ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  # This clause handles default errors returned by control actions.
  def call(conn, {:error, error}) do
    {status, message} = Keyword.get(@error_templates, error, {400, "Bad request"})

    conn
    |> put_status(status)
    |> put_view(ErrorView)
    |> render("error.json", error: %{status: status, detail: message, code: error})
  end
end
