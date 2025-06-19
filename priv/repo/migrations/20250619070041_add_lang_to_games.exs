defmodule CrimeToGo.Repo.Migrations.AddLangToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :lang, :string, size: 5, null: false, default: "en"
    end

    create index(:games, [:lang])
  end
end
