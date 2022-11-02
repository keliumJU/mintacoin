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

  @supported_errors [:not_found, :bad_request]
  @error_templates [bad_request: :"400", not_found: :"404"]

  # This clause handles errors returned by Ecto's insert/update/delete.
  @spec call(conn :: conn(), {:error, error()}) :: conn()
  def call(conn, {:error, %Changeset{} = changeset}) do
    conn
    |> put_status(:bad_request)
    |> put_view(ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  # This clause handles default errors returned by control actions.
  def call(conn, {:error, error}) when error in @supported_errors do
    conn
    |> put_status(error)
    |> put_view(ErrorView)
    |> render(@error_templates[error])
  end

  # This clause handles errors that have a specific response code and will be displayed by the associated view.
  def call(conn, {:error, %{status: status} = error}) do
    conn
    |> put_status(status)
    |> render("error.json", error: error)
  end
end
