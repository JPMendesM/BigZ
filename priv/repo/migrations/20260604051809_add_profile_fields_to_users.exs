defmodule Bigz.Repo.Migrations.AddProfileFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :string, null: false, default: ""
      add :bio, :text, null: false, default: ""
      add :score, :integer, null: false, default: 0
    end
  end
end
