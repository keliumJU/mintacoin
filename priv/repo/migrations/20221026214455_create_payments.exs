defmodule Mintacoin.Repo.Migrations.CreatePayments do
  use Ecto.Migration

  def change do
    create table(:payments, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:blockchain_id, references(:blockchains, type: :uuid), null: false)
      add(:source_account_id, references(:accounts, type: :uuid), null: false)
      add(:destination_account_id, references(:accounts, type: :uuid), null: false)
      add(:asset_id, references(:assets, type: :uuid), null: false)
      add(:amount, :string, null: false)
      add(:status, :string, null: false)
      add(:successful, :boolean, null: false)

      timestamps()
    end
  end
end
