defmodule MintacoinWeb.ErrorView do
  use MintacoinWeb, :view
  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end

  def render("401.json", %{message: message}),
    do: %{status: :unauthorized, code: 401, detail: message}

  def render("400.json", %{status: status, code: code}),
    do: %{status: status, code: code, detail: error_msg(code)}

  defp error_msg(:blockchain_not_found), do: "The introduced blockchain doesn't exist"
  defp error_msg(:decoding_error), do: "The signature is invalid"
  defp error_msg(:invalid_address), do: "The address is invalid"
  defp error_msg(:invalid_seed_words), do: "The seed words are invalid"
  defp error_msg(:asset_not_found), do: "The introduced asset doesn't exist"

  defp error_msg(:wallet_not_found),
    do: "The introduced address doesn't exist or doesn't have associated the blockchain"

  defp error_msg(:bad_request), do: "The body params are invalid"
  defp error_msg(:invalid_supply_format), do: "The introduced supply format is invalid"
end
