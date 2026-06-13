defmodule BigzWeb.UserLive.Profile do
  use BigzWeb, :live_view

  alias Bigz.Accounts
  alias Bigz.Habits

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} active={:profile}>
      <div class="mx-auto max-w-2xl space-y-6">
        <div>
          <h1 class="text-3xl font-extrabold tracking-tight">Meu perfil</h1>
          
          <p class="text-sm text-base-content/60 mt-1">
            Suas informações pessoais e sua evolução no Big Z.
          </p>
        </div>
         <%!-- Profile card --%>
        <div class="rounded-box bg-base-100 border border-base-300 shadow-sm overflow-hidden">
          <div class="h-24 bg-gradient-to-r from-primary/20 via-secondary/15 to-accent/20"></div>
          
          <div class="px-6 pb-6">
            <div class="flex items-end justify-between -mt-10">
              <span class="grid place-items-center size-20 rounded-full bg-secondary text-secondary-content text-2xl font-bold uppercase ring-4 ring-base-100">
                {initials(@user)}
              </span>
              <div :if={!@editing} class="pb-1">
                <button phx-click="edit" class="btn btn-primary btn-sm gap-2">
                  <.icon name="hero-pencil-square" class="size-4" /> Editar perfil
                </button>
              </div>
            </div>
            
            <%= if @editing do %>
              <.form
                for={@form}
                id="profile_form"
                phx-submit="save"
                phx-change="validate"
                class="mt-6 space-y-4"
              >
                <.input field={@form[:name]} type="text" label="Nome" required />
                <.input
                  field={@form[:bio]}
                  type="textarea"
                  label="Bio"
                  rows={4}
                  placeholder="Conte um pouco sobre você e seus hábitos sustentáveis..."
                />
                <div class="flex justify-end gap-2 pt-2">
                  <button type="button" phx-click="cancel" class="btn btn-ghost">Cancelar</button>
                  <.button variant="primary" phx-disable-with="Salvando..." class="btn btn-primary">
                    Salvar alterações
                  </.button>
                </div>
              </.form>
            <% else %>
              <div class="mt-4 space-y-4">
                <div>
                  <h2 class="text-xl font-bold">{@user.name}</h2>
                  
                  <p class="text-sm text-base-content/50 flex items-center gap-1.5 mt-0.5">
                    <.icon name="hero-envelope" class="size-4" /> {@user.email}
                  </p>
                </div>
                
                <div>
                  <p class="text-xs font-semibold uppercase tracking-wider text-base-content/40">
                    Bio
                  </p>
                  
                  <p class="text-sm text-base-content/70 mt-1 leading-relaxed">
                    <%= if @user.bio && @user.bio != "" do %>
                      {@user.bio}
                    <% else %>
                      <span class="text-base-content/40 italic">
                        Você ainda não escreveu uma bio.
                      </span>
                    <% end %>
                  </p>
                </div>
              </div>
            <% end %>
          </div>
        </div>
         <%!-- Stats + account link --%>
        <div class="grid sm:grid-cols-2 gap-4">
          <.stat_card
            label="Pontuação total"
            value={@total_points}
            icon="hero-bolt"
            tone="success"
            hint="pontos acumulados via check-ins"
          />
          <.link
            navigate={~p"/users/settings"}
            class="bz-lift rounded-box bg-base-100 border border-base-300 p-5 shadow-sm flex items-center justify-between gap-3"
          >
            <span class="flex items-center gap-3">
              <span class="grid place-items-center size-9 rounded-field bg-secondary/10 text-secondary">
                <.icon name="hero-cog-6-tooth" class="size-5" />
              </span>
              <span>
                <span class="block font-semibold">Conta e segurança</span>
                <span class="block text-xs text-base-content/50">E-mail e senha</span>
              </span>
            </span> <.icon name="hero-chevron-right" class="size-5 text-base-content/40" />
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    user = scope.user
    changeset = Accounts.change_user_profile(user)

    {:ok,
     socket
     |> assign(:page_title, "Meu perfil")
     |> assign(:user, user)
     |> assign(:total_points, Habits.sum_user_points(scope))
     |> assign(:editing, false)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("edit", _params, socket) do
    {:noreply, assign(socket, :editing, true)}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing, false)
     |> assign_form(Accounts.change_user_profile(socket.assigns.user))}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.update_user_profile(socket.assigns.user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:user, user)
         |> assign(:editing, false)
         |> assign_form(Accounts.change_user_profile(user))
         |> put_flash(:info, "Perfil atualizado com sucesso.")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset, as: "user"))
  end

  defp initials(%{name: name}) when is_binary(name) and name != "" do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", &String.slice(&1, 0, 1))
    |> String.upcase()
  end

  defp initials(%{email: email}) when is_binary(email),
    do: String.slice(email, 0, 2) |> String.upcase()

  defp initials(_), do: "BZ"
end
