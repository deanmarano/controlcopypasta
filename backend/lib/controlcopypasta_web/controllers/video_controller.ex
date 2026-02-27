defmodule ControlcopypastaWeb.VideoController do
  use ControlcopypastaWeb, :controller

  @video_dir "/mnt/iota/controlcopypasta/videos"

  def show(conn, %{"filename" => filename}) do
    if valid_filename?(filename) do
      filepath = Path.join(@video_dir, filename)

      if File.exists?(filepath) do
        conn
        |> put_resp_content_type("video/mp4", nil)
        |> send_file(200, filepath)
      else
        conn
        |> put_status(404)
        |> json(%{error: "Video not found"})
      end
    else
      conn
      |> put_status(400)
      |> json(%{error: "Invalid filename"})
    end
  end

  defp valid_filename?(filename) do
    Regex.match?(~r/^[A-Za-z0-9_-]+\.mp4$/, filename)
  end
end
