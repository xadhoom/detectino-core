defmodule DtWeb.Router do
  use DtWeb.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Guardian.Plug.VerifyHeader
    plug Guardian.Plug.LoadResource
  end

  scope "/", DtWeb do
    pipe_through [:browser] # Use the default browser stack
    get "/", PageController, :index
    get "/login", PageController, :index
    get "/about", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", DtWeb do
    pipe_through :api

    post "/login", SessionController, :create, as: :api_login

    resources "/users", UserController

    resources "/scenarios", ScenarioController do
      resources "/rules", RuleController
    end

  end

end
