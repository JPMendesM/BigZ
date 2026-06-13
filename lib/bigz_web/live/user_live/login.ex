defmodule BigzWeb.UserLive.Login do
  use BigzWeb, :live_view

  alias Bigz.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash} current_scope={@current_scope}>
      <:actions>
        <.link :if={!@current_scope} navigate={~p"/users/register"} class="btn btn-ghost btn-sm">
          Criar conta
        </.link>
      </:actions>

      <div class="space-y-6">
        <div>
          <h1 class="text-2xl font-extrabold tracking-tight">Entrar</h1>

          <p class="text-sm text-base-content/60 mt-1">
            <%= if @current_scope do %>
              Você precisa confirmar sua identidade para realizar ações sensíveis na conta.
            <% else %>
              Ainda não tem conta? <.link
                navigate={~p"/users/register"}
                class="font-semibold text-primary hover:underline"
                phx-no-format
              >Criar conta</.link> e comece agora.
            <% end %>
          </p>
        </div>

        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/users/log-in"}
          phx-submit="submit_magic"
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
            phx-mounted={JS.focus()}
          />
          <.button class="btn btn-primary w-full">
            Entrar com link por e-mail <span aria-hidden="true">→</span>
          </.button>
        </.form>

        <div class="divider text-base-content/40">ou</div>

        <.form
          :let={f}
          for={@form}
          id="login_form_password"
          action={~p"/users/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
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
            autocomplete="current-password"
            spellcheck="false"
          />
          <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
            Entrar e permanecer logado <span aria-hidden="true">→</span>
          </.button>
          <.button class="btn btn-primary btn-soft w-full mt-2">Entrar apenas desta vez</.button>
        </.form>
      </div>
    </Layouts.auth>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "Se este e-mail estiver cadastrado, você receberá as instruções de acesso em instantes."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end
end
