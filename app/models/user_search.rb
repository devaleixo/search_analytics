class UserSearch < ApplicationRecord
    validates :ip_address, presence: true
    validates :query, presence: true

    def self.clean_pyramid_queries_for(ip_address)
        user_searches = where(ip_address: ip_address)
                        .where(created_at: 2.minutes.ago..Time.current)
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
      
        where(ip_address: ip_address)
          .where.not(id: to_keep.map(&:id))
          .destroy_all
      end

  def self.remove_duplicates_for(ip_address)
    searches = where(ip_address: ip_address).order(created_at: :desc)
    
    to_keep = searches.each_with_object({}) do |search, hash|
      normalized = search.query.strip.downcase
      if !hash[normalized] || search.created_at > hash[normalized].created_at
        hash[normalized] = search
      end
    end.values
    
    where(ip_address: ip_address)
      .where.not(id: to_keep.map(&:id))
      .destroy_all
  end
end
