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

  # Other scopes may use custom stacks.
  scope "/api", DtWeb do
    pipe_through :api

    post "/login", SessionController, :create, as: :api_login
    post "/login/refresh", SessionController, :refresh, as: :api_login

    post "/partitions/:id/arm", PartitionController, :arm
    post "/partitions/:id/disarm", PartitionController, :disarm
    resources "/partitions", PartitionController, only: @api_methods

    post "/scenarios/:id/run", ScenarioController, :run
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

    put "/eventlogs/ackall", EventLogController, :ackall
    put "/eventlogs/:id/ack", EventLogController, :ack
    resources "/eventlogs", EventLogController, only: @api_methods

    post "/users/check_pin", UserController, :check_pin
    post "/users/:id/invalidate", SessionController, :invalidate, as: :api_login
    resources "/users", UserController, only: @api_methods

    get "/*path", NotImplementedController, :not_impl
    post "/*path", NotImplementedController, :not_impl
    put "/*path", NotImplementedController, :not_impl
    patch "/*path", NotImplementedController, :not_impl
    delete "/*path", NotImplementedController, :not_impl
  end

  scope "/", DtWeb do
    pipe_through [:browser] # Use the default browser stack
    get "/*path", PageController, :index
    #get "/home", PageController, :index
    #get "/login", PageController, :index
    #get "/about", PageController, :index
  end

end
