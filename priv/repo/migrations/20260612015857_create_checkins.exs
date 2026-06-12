defmodule Bigz.Repo.Migrations.CreateCheckins do
  use Ecto.Migration

  def change do
    create table(:checkins) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :habit_id, references(:habits, on_delete: :delete_all), null: false
      # Always set server-side via Date.utc_today/0 — "same day" is evaluated in UTC.
      add :checkin_date, :date, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:checkins, [:user_id])
    create index(:checkins, [:habit_id])
    create unique_index(:checkins, [:user_id, :habit_id, :checkin_date])
  end
end
