defmodule SanehRoiRosWeb.Router do
  use SanehRoiRosWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SanehRoiRosWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SanehRoiRosWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # จัดการเมนู — managers and the owner only.
  scope "/", SanehRoiRosWeb do
    pipe_through :browser

    live_session :menu,
      on_mount: [
        {SanehRoiRosWeb.StaffAccess, :menu},
        SanehRoiRosWeb.Toast,
        SanehRoiRosWeb.MainNav
      ] do
      live "/menu", MenuLive.Index, :index
      live "/menu/new", MenuLive.Form, :new
      live "/menu/:id/edit", MenuLive.Form, :edit
    end
  end

  # Interactive gallery of the SanehRoiRosUI components (dev and test only).
  if Application.compile_env(:saneh_roi_ros, :ui_gallery, false) do
    scope "/dev", SanehRoiRosWeb do
      pipe_through :browser

      live "/ui", UIGalleryLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", SanehRoiRosWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:saneh_roi_ros, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SanehRoiRosWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
