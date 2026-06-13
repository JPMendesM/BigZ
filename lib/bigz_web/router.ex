defmodule BigzWeb.Router do
  use BigzWeb, :router

  import BigzWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BigzWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BigzWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  if Application.compile_env(:bigz, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BigzWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", BigzWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{BigzWeb.UserAuth, :require_authenticated}] do
      live "/inicio", HomeLive.Index, :index
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/profile", UserLive.Profile, :edit
      live "/habits/new", HabitLive.Index, :new
      live "/habits/:id/edit", HabitLive.Index, :edit
      live "/habits/:habit_id/checkin", CheckinLive.New, :new
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", BigzWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{BigzWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
      live "/habits", HabitLive.Index, :index
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
