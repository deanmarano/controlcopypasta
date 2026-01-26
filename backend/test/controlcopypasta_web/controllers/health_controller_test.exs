defmodule ControlcopypastaWeb.HealthControllerTest do
  use ControlcopypastaWeb.ConnCase

  describe "GET /api/health" do
    test "returns ok status when database is connected", %{conn: conn} do
      conn = get(conn, "/api/health")

      assert json_response(conn, 200) == %{
               "status" => "ok",
               "database" => "connected"
             }
    end
  end
end
