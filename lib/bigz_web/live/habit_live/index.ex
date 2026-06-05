defmodule BigzWeb.HabitLive.Index do
  use BigzWeb, :live_view

  alias Bigz.Habits
  alias Bigz.Habits.Habit

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    category = Map.get(params, "category")

    # Pass current_scope as the first argument as required by guidelines
    habits = Habits.list_habits(socket.assigns.current_scope, %{"category" => category})

    socket =
      socket
      |> assign(:category_filter, category)
      |> stream(:habits, habits, reset: true)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "EcoHabits - Hábitos Sustentáveis")
    |> assign(:habit, nil)
  end

  defp apply_action(socket, :new, _params) do
    habit = %Habit{}
    changeset = Habits.change_habit(socket.assigns.current_scope, habit)

    socket
    |> assign(:page_title, "Novo Hábito")
    |> assign(:habit, habit)
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    habit = Habits.get_habit!(socket.assigns.current_scope, id)
    user = socket.assigns.current_scope.user

    if user && habit.user_id == user.id do
      changeset = Habits.change_habit(socket.assigns.current_scope, habit)

      socket
      |> assign(:page_title, "Editar Hábito")
      |> assign(:habit, habit)
      |> assign(:form, to_form(changeset))
    else
      socket
      |> put_flash(:error, "Você não tem permissão para editar este hábito.")
      |> push_navigate(to: ~p"/habits")
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    habit = Habits.get_habit!(socket.assigns.current_scope, id)

    case Habits.delete_habit(socket.assigns.current_scope, habit) do
      {:ok, _habit} ->
        {:noreply,
         socket
         |> put_flash(:info, "Hábito removido com sucesso!")
         |> stream_delete(:habits, habit)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Não autorizado.")}
    end
  end

  @impl true
  def handle_event("validate", %{"habit" => habit_params}, socket) do
    changeset =
      Habits.change_habit(socket.assigns.current_scope, socket.assigns.habit, habit_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"habit" => habit_params}, socket) do
    save_habit(socket, socket.assigns.live_action, habit_params)
  end

  defp save_habit(socket, :new, habit_params) do
    case Habits.create_habit(socket.assigns.current_scope, habit_params) do
      {:ok, _habit} ->
        {:noreply,
         socket
         |> put_flash(:info, "Hábito cadastrado com sucesso!")
         |> push_navigate(to: ~p"/habits")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_habit(socket, :edit, habit_params) do
    case Habits.update_habit(socket.assigns.current_scope, socket.assigns.habit, habit_params) do
      {:ok, _habit} ->
        {:noreply,
         socket
         |> put_flash(:info, "Hábito atualizado com sucesso!")
         |> push_navigate(to: ~p"/habits")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "Não autorizado.")
         |> push_navigate(to: ~p"/habits")}
    end
  end
end
