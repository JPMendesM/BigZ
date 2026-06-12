defmodule BigzWeb.UserLive.Profile do
  use BigzWeb, :live_view

  alias Bigz.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-xl">
        <.header>
          Meu Perfil
          <:subtitle>Visualize e edite suas informações pessoais.</:subtitle>
        </.header>
        
        <div class="mt-6 rounded-lg border border-base-300 bg-base-100 p-6">
          <p class="mb-2"><strong>Nome:</strong> {@user.name}</p>
          
          <p class="mb-6"><strong>Pontuação total:</strong> {@user.score || 0} pontos</p>
          
          <.form for={@form} id="profile_form" phx-submit="save" phx-change="validate">
            <.input
              field={@form[:name]}
              type="text"
              label="Nome"
              required
            />
            <.input
              field={@form[:bio]}
              type="textarea"
              label="Bio"
              placeholder="Conte um pouco sobre você e seus hábitos sustentáveis..."
            />
            <.button phx-disable-with="Salvando..." class="btn btn-primary w-full">
              Salvar alterações
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    changeset = Accounts.change_user_profile(user)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign_form(changeset)}
  end

  @impl true
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
         |> assign_form(Accounts.change_user_profile(user))
         |> put_flash(:info, "Perfil atualizado com sucesso.")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset, as: "user"))
  end
end
