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

  def render("error.json", %{message: message}), do: %{status: :error, message: message}

  def render("400.json", %{status: status, code: code}),
    do: %{status: status, code: code, detail: error_msg(status)}

  defp error_msg(:blockchain_not_found), do: "The introduced blockchain doesn't exist"
  defp error_msg(:invalid_address), do: "The address is invalid"
  defp error_msg(:invalid_seed_words), do: "The seed words are invalid"
  defp error_msg(:encryption_error), do: "The seed words are invalid"
  defp error_msg(:asset_not_found), do: "Error during encryption"
  defp error_msg(:wallet_not_found), do: "The address entered does not exist or does not have the blockchain associated with it"
  defp error_msg(_nothing), do: "Error in x controller"
  defp error_msg(error), do: "Error in x controller"

end
