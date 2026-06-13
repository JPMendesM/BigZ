defmodule BigzWeb.UserLive.Registration do
  use BigzWeb, :live_view

  alias Bigz.Accounts
  alias Bigz.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash} current_scope={@current_scope}>
      <:actions>
        <.link navigate={~p"/users/log-in"} class="btn btn-ghost btn-sm">Log in</.link>
      </:actions>

      <div class="space-y-6">
        <div>
          <p class="text-xs font-semibold uppercase tracking-wider text-primary">Register</p>
          <h1 class="text-2xl font-extrabold tracking-tight mt-1">Criar sua conta</h1>
          <p class="text-sm text-base-content/60 mt-1">
            Já possui cadastro?
            <.link navigate={~p"/users/log-in"} class="font-semibold text-primary hover:underline">
              Entrar
            </.link>
            agora.
          </p>
        </div>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:name]}
            type="text"
            label="Nome"
            autocomplete="name"
            required
            phx-mounted={JS.focus()}
          />
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label="Senha"
            autocomplete="new-password"
            required
          />
          <.input
            field={@form[:password_confirmation]}
            type="password"
            label="Confirmar senha"
            autocomplete="new-password"
            required
          />
          <.button phx-disable-with="Criando conta..." class="btn btn-primary w-full">
            Criar conta
          </.button>
        </.form>
      </div>
    </Layouts.auth>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: BigzWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Conta criada com sucesso.")
         |> push_navigate(to: ~p"/users/log-in")}

        {:noreply,
         socket
         |> put_flash(
           :info,
           "Um email foi enviado para #{user.email}. Acesse para confirmar sua conta."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
