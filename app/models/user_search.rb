class UserSearch < ApplicationRecord
    validates :ip_address, presence: true
    validates :query, presence: true

    def filter_query
    end
end
