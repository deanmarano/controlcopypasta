defmodule Controlcopypasta.Accounts.Email do
  import Swoosh.Email

  alias Controlcopypasta.Mailer

  @from_email "noreply@controlcopypasta.local"
  @from_name "ControlCopyPasta"

  def send_magic_link(email, token, base_url \\ nil) do
    magic_link_url = build_magic_link_url(token, base_url)

    new()
    |> to(email)
    |> from({@from_name, @from_email})
    |> subject("Sign in to ControlCopyPasta")
    |> html_body("""
    <h1>Sign in to ControlCopyPasta</h1>
    <p>Click the link below to sign in. This link will expire in 10 minutes.</p>
    <p><a href="#{magic_link_url}">Sign in to ControlCopyPasta</a></p>
    <p>Or copy and paste this URL into your browser:</p>
    <p>#{magic_link_url}</p>
    <p>If you didn't request this email, you can safely ignore it.</p>
    """)
    |> text_body("""
    Sign in to ControlCopyPasta

    Click the link below to sign in. This link will expire in 10 minutes.

    #{magic_link_url}

    If you didn't request this email, you can safely ignore it.
    """)
    |> Mailer.deliver()
  end

  defp build_magic_link_url(token, base_url) do
    frontend_url = base_url || Application.get_env(:controlcopypasta, :frontend_url, "http://localhost:5173")
    "#{frontend_url}/auth/verify?token=#{token}"
  end
end
