class UserSearch < ApplicationRecord
    validates :ip_address, presence: true
    validates :query, presence: true

    def self.clean_pyramid_queries_for(ip_address)
        user_searches = where(ip_address: ip_address)
                        .order(created_at: :desc)
      
        to_keep = []
        processed_queries = Set.new
      
        user_searches.each do |search|
          query = search.query.strip.downcase
      
          next if processed_queries.include?(query)
      
          is_redundant = to_keep.any? do |s|
            s.query.strip.downcase.start_with?(query + ' ') &&
            s.created_at > search.created_at
          end
      
          unless is_redundant
            to_keep << search
            processed_queries << query
          end
        end
      
        # Exclui os registros que não fazem parte do conjunto "válido"
        where(ip_address: ip_address)
          .where.not(id: to_keep.map(&:id))
          .destroy_all
      end
      
end
