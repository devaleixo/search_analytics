class CreateUserSearches < ActiveRecord::Migration[8.0]
  def change
    create_table :user_searches do |t|
      t.string :ip_address
      t.string :query

      t.timestamps
    end
  end
end
