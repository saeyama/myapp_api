class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :cognito_sub
      t.string :email
      t.string :nickname

      t.timestamps
    end
    add_index :users, :cognito_sub
  end
end
