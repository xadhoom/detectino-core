defmodule DtWeb.Router do
  use DtWeb.Web, :router

  @api_methods [:index, :show, :create, :update, :delete]

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
    get "/home", PageController, :index
    get "/login", PageController, :index
    get "/about", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", DtWeb do
    pipe_through :api

    post "/login", SessionController, :create, as: :api_login

    resources "/partitions", PartitionController, only: @api_methods

    get "/scenarios/:id/run", ScenarioController, :run
    get "/scenarios/get_available", ScenarioController, :get_available
    resources "/scenarios", ScenarioController, only: @api_methods do
      resources "/partitions_scenarios",
        PartitionScenarioController, only: @api_methods
    end

    resources "/sensors", SensorController, only: @api_methods do
      resources "/partitions_sensors",
        PartitionSensorController, only: @api_methods
    end

    resources "/outputs", OutputController, only: @api_methods

    resources "/events", EventController, only: @api_methods

    post "/users/check_pin", UserController, :check_pin
    resources "/users", UserController, only: @api_methods

  end

end
