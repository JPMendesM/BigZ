defmodule BigzWeb.UserLive.Settings do
  use BigzWeb, :live_view

  on_mount {BigzWeb.UserAuth, :require_sudo_mode}

  alias Bigz.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} active={:settings}>
      <div class="mx-auto max-w-2xl space-y-6">
        <div>
          <h1 class="text-3xl font-extrabold tracking-tight">Conta e segurança</h1>
          
          <p class="text-sm text-base-content/60 mt-1">Gerencie seu e-mail de acesso e sua senha.</p>
        </div>
         <%!-- E-mail --%>
        <div class="rounded-box bg-base-100 border border-base-300 shadow-sm p-6">
          <div class="flex items-center gap-2 mb-4">
            <span class="grid place-items-center size-9 rounded-field bg-secondary/10 text-secondary">
              <.icon name="hero-envelope" class="size-5" />
            </span>
            <h2 class="text-lg font-bold">E-mail</h2>
          </div>
          
          <.form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
          >
            <.input
              field={@email_form[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              spellcheck="false"
              required
            />
            <.button variant="primary" class="btn btn-primary" phx-disable-with="Alterando...">
              Alterar e-mail
            </.button>
          </.form>
        </div>
         <%!-- Senha --%>
        <div class="rounded-box bg-base-100 border border-base-300 shadow-sm p-6">
          <div class="flex items-center gap-2 mb-4">
            <span class="grid place-items-center size-9 rounded-field bg-primary/10 text-primary">
              <.icon name="hero-lock-closed" class="size-5" />
            </span>
            <h2 class="text-lg font-bold">Senha</h2>
          </div>
          
          <.form
            for={@password_form}
            id="password_form"
            action={~p"/users/update-password"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
          >
            <input
              name={@password_form[:email].name}
              type="hidden"
              id="hidden_user_email"
              spellcheck="false"
              value={@current_email}
            />
            <.input
              field={@password_form[:password]}
              type="password"
              label="Nova senha"
              autocomplete="new-password"
              spellcheck="false"
              required
            />
            <.input
              field={@password_form[:password_confirmation]}
              type="password"
              label="Confirmar nova senha"
              autocomplete="new-password"
              spellcheck="false"
            />
            <.button variant="primary" class="btn btn-primary" phx-disable-with="Salvando...">
              Salvar senha
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "E-mail alterado com sucesso.")

        {:error, _} ->
          put_flash(socket, :error, "O link para alterar o e-mail é inválido ou expirou.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "Um link para confirmar a alteração de e-mail foi enviado para o novo endereço."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end
