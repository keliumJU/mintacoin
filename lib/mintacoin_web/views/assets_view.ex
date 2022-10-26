defmodule MintacoinWeb.AssetsView do
  @moduledoc """
  This module contains the JSON response for the asset's endpoints
  """

  alias Mintacoin.{Asset, AssetHolder}

  @type template :: String.t()
  @type assigns :: map()
  @type json :: map()

  @spec render(template :: template(), assigns :: assigns()) :: json()
  def render("asset.json", %{resource: %Asset{id: id, code: code, supply: supply}}),
    do: %{status: 201, data: %{id: id, code: code, supply: supply}}

  def render("show_asset.json", %{resource: %Asset{id: id, code: code, supply: supply}}),
    do: %{status: 200, data: %{id: id, code: code, supply: supply}}

  def render("asset_issuer.json", %{resource: %AssetHolder{account: %{address: address}}}),
    do: %{status: 200, data: %{address: address}}

  def render("asset_accounts.json", %{resource: accounts}) do
    addresses = Enum.map(accounts, fn %{address: address} -> address end)
    %{status: 200, data: %{addresses: addresses}}
  end

  #probabli create a generic error for show the errors or only one render error.json
  def render("error.json", %{error: %{status: status, code: code, detail: detail}}),
    do: %{status: status, code: code, detail: detail}
end
