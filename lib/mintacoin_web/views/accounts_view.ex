defmodule MintacoinWeb.AccountsView do
  @moduledoc """
  This module contains the JSON response for the account's endpoints
  """

  alias Mintacoin.{Account, Asset, AssetHolder, Balance}

  @type template :: String.t()
  @type assigns :: map()
  @type json :: map()
  @type asset_information :: {AssetHolder.t(), Balance.t()}
  @type formatted_asset_data :: map()

  @spec render(template :: template(), assigns :: assigns()) :: json()
  def render("account.json", %{
        resource: %Account{address: address, signature: signature, seed_words: seed_words}
      }),
      do: %{status: 201, data: %{address: address, signature: signature, seed_words: seed_words}}

  def render("signature.json", %{resource: signature}),
    do: %{status: 200, data: %{signature: signature}}

  def render("trustline.json", %{resource: %Asset{id: id, code: code, supply: supply}}),
    do: %{status: 201, data: %{id: id, code: code, supply: supply}}

  def render("assets.json", %{resource: resource}) do
    assets_data = Enum.map(resource, &format_asset/1)

    %{status: 200, data: assets_data}
  end

  #move after test the new code
  def render("error.json", %{error: %{status: status, code: code, detail: detail}}),
    do: %{status: status, code: code, detail: detail}

  @spec format_asset(asset_information :: asset_information()) :: formatted_asset_data()
  defp format_asset(
         {%AssetHolder{
            blockchain: %{name: blockchain_name},
            is_minter: is_minter,
            asset: %{id: asset_id, code: asset_code}
          }, %Balance{balance: balance}}
       ) do
    %{
      blockchain: blockchain_name,
      minter: is_minter,
      asset_id: asset_id,
      asset: asset_code,
      balance: balance
    }
  end
end
